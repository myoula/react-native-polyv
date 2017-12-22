package com.whalew.polyv;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

import android.util.Log;
import android.text.TextUtils;
import android.support.annotation.NonNull;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import com.easefun.polyvsdk.PolyvSDKClient;
import com.easefun.polyvsdk.PolyvDevMountInfo;
import com.easefun.polyvsdk.PolyvDownloaderManager;
import com.easefun.polyvsdk.PolyvDownloader;
import com.easefun.polyvsdk.PolyvDownloaderErrorReason;

import com.easefun.polyvsdk.live.PolyvLiveSDKClient;
import com.easefun.polyvsdk.live.chat.PolyvChatManager;

import com.easefun.polyvsdk.download.listener.IPolyvDownloaderProgressListener;
import com.easefun.polyvsdk.download.listener.IPolyvDownloaderSpeedListener;
import com.easefun.polyvsdk.download.listener.IPolyvDownloaderStartListener;

public class ReactPolyvModule extends ReactContextBaseJavaModule {

	private ReactApplicationContext reactContext;
	private Map<String, PolyvDownloader> downloaders = new HashMap<>();

	public ReactPolyvModule(ReactApplicationContext reactContext) {
		super(reactContext);
		this.reactContext = reactContext;
	}

	@Override
	public String getName() {
		return "Polyv";
	}

	@ReactMethod
	public void init(String appId, String appKey, String appSecret) {

		PolyvSDKClient client = PolyvSDKClient.getInstance();
		client.setConfig(appKey, reactContext.getApplicationContext());
		client.initSetting(reactContext.getApplicationContext());

		PolyvLiveSDKClient.getInstance();
		PolyvChatManager.initConfig(appId, appSecret);


		PolyvDevMountInfo.getInstance().init(reactContext, new PolyvDevMountInfo.OnLoadCallback() {
			
			@Override
			public void callback() {

				if (!PolyvDevMountInfo.getInstance().isSDCardAvaiable()) {
					return;
				}

				String externalSDCardPath = PolyvDevMountInfo.getInstance().getExternalSDCardPath();
				if (!TextUtils.isEmpty(externalSDCardPath)) {
					StringBuilder dirPath = new StringBuilder();
					dirPath.append(externalSDCardPath).append(File.separator).append("Android").append(File.separator).append("data")
							.append(File.separator).append(reactContext.getPackageName()).append(File.separator).append("polyvdownload");
					File saveDir = new File(dirPath.toString());
					if (!saveDir.exists()) {
						reactContext.getExternalFilesDir(null);
						saveDir.mkdirs();
					}

					PolyvSDKClient.getInstance().setDownloadDir(saveDir);
					return;
				}

				File saveDir = new File(PolyvDevMountInfo.getInstance().getInternalSDCardPath() + File.separator + "polyvdownload");
				if (!saveDir.exists()) {
					saveDir.mkdirs();//创建下载目录
				}

				PolyvSDKClient.getInstance().setDownloadDir(saveDir);
			}
		});

		PolyvDownloaderManager.setDownloadQueueCount(1);
	}

	private static class DownloadListener implements IPolyvDownloaderProgressListener {

		private String vid;

		DownloadListener(String vid) {
			this.vid = vid;
		}

		@Override
		public void onDownload(long current, long total) {
			Log.i("polyv", String.format("download current = %d. total = %d", current, total));
		}

		@Override
		public void onDownloadSuccess() {
			Log.i("polyv", "download over");
		}

		@Override
		public void onDownloadFail(@NonNull PolyvDownloaderErrorReason reason) {
			Log.i("polyv", "download error");
		}
	};

	@ReactMethod
	public void download(String vid, int level) {
		PolyvDownloader downloader = PolyvDownloaderManager.getPolyvDownloader(vid, level);

		downloader.setPolyvDownloadProressListener(new DownloadListener(vid));
		downloader.start(reactContext.getApplicationContext());
		
		downloaders.put(vid, downloader);
	}

	@ReactMethod
	public void start(String vid) {
		PolyvDownloader downloader = downloaders.get(vid);

		if (downloader != null) {
			downloader.start(reactContext.getApplicationContext());
		}
	}

	@ReactMethod
	public void stop(String vid) {
		PolyvDownloader downloader = downloaders.get(vid);

		if (downloader != null) {
			downloader.stop();
		}
	}

	@ReactMethod
	public void delete(String vid) {
		PolyvDownloader downloader = downloaders.get(vid);

		if (downloader != null) {
			downloader.deleteVideo();
		} else {
			downloader = PolyvDownloaderManager.getPolyvDownloader(vid, 1);
			if (downloader != null) {
				downloader.deleteVideo();
			}
		}
	}

	@ReactMethod
	public void clean() {
		
	}
}