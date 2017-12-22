package com.whalew.polyv;

import android.util.Log;
import android.os.Handler;
import android.os.Message;
import android.os.Looper;
import java.util.Map;
import javax.annotation.Nullable;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.events.RCTEventEmitter;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;

import com.easefun.polyvsdk.video.PolyvVideoView;
import com.easefun.polyvsdk.video.PolyvMediaInfoType;
import com.easefun.polyvsdk.video.PolyvPlayErrorReason;
import com.easefun.polyvsdk.video.listener.IPolyvOnPlayPauseListener;
import com.easefun.polyvsdk.video.listener.IPolyvOnCompletionListener2;
import com.easefun.polyvsdk.video.listener.IPolyvOnErrorListener2;
import com.easefun.polyvsdk.video.listener.IPolyvOnInfoListener2;
import com.easefun.polyvsdk.video.listener.IPolyvOnPreparedListener2;
import com.easefun.polyvsdk.video.listener.IPolyvOnVideoPlayErrorListener2;
import com.easefun.polyvsdk.video.listener.IPolyvOnVideoStatusListener;


public class ReactPlayerViewManager extends SimpleViewManager<PolyvVideoView> implements LifecycleEventListener {

	public static final String REACT_CLASS = "RCTPlayer";
	private static final int SHOW_PROGRESS = 1;

	private RCTEventEmitter mEventEmitter;
	private ThemedReactContext reactContext = null;
	private PolyvVideoView mVideoView = null;

	public enum Events {
		LOADING("onLoading"),
		LOADED("onLoaded"),
		PLAYING("onPlaying"),
		PAUSED("onPaused"),
		STOP("onStop"),
		ERROR("onError");

		private final String mName;

		Events(final String name) {
			mName = name;
		}

		@Override
		public String toString() {
			return mName;
		}
	}

	@Override
	public String getName() {
		return REACT_CLASS;
	}

	@Override
	@Nullable
	public Map getExportedCustomDirectEventTypeConstants() {
		MapBuilder.Builder builder = MapBuilder.builder();
		for (Events event : Events.values()) {
			builder.put(event.toString(), MapBuilder.of("registrationName", event.toString()));
		}

		return builder.build();
	}

	@Override
	protected PolyvVideoView createViewInstance(ThemedReactContext reactContext) {

		this.reactContext = reactContext;
		mEventEmitter = reactContext.getJSModule(RCTEventEmitter.class);
		mVideoView = new PolyvVideoView(reactContext.getApplicationContext());

		mVideoView.setOnPreparedListener(mIPolyvOnPreparedListener2);
		mVideoView.setOnPlayPauseListener(mIPolyvOnPlayPauseListener);
		mVideoView.setOnInfoListener(mIPolyvOnInfoListener2);
		mVideoView.setOnVideoStatusListener(mIPolyvOnVideoStatusListener);
		mVideoView.setOnVideoPlayErrorListener(mIPolyvOnVideoPlayErrorListener2);
		mVideoView.setOnErrorListener(mIPolyvOnErrorListener2);
		mVideoView.setOnCompletionListener(mIPolyvOnCompletionListener2);

		reactContext.addLifecycleEventListener(this);
		return mVideoView;
	}

	@Override
    public void onDropViewInstance(PolyvVideoView view) {
		super.onDropViewInstance(view);
		Log.i("polyv", "drop");

		handler.removeMessages(SHOW_PROGRESS);
		
		if (mVideoView != null) {
			mVideoView.pause();
		}
    }


	@ReactProp(name = "source")
	public void setSource(PolyvVideoView mVideoView, ReadableMap source) {
		String vid = source.getString("vid");
		mVideoView.setVid(vid);
	}

	@ReactProp(name = "paused")
	public void setPaused(PolyvVideoView mVideoView,  boolean paused) {
	 	if (paused) {
	 		mVideoView.pause();
	 	} else {
	 		mVideoView.start();
	 	}
	}

	@ReactProp(name = "seek")
	public void setSeek(PolyvVideoView mVideoView,  int seek) {
	 	mVideoView.pause();
	 	mVideoView.seekTo(seek * 1000);
	 	mVideoView.start();
	}

	private Handler handler = new Handler(Looper.getMainLooper()) {
		@Override
		public void handleMessage(Message msg) {
			switch (msg.what) {
				case SHOW_PROGRESS:
				track();
				break;
			}
		}
	};

	private void track() {
		int position = mVideoView.getCurrentPosition();

		WritableMap event = Arguments.createMap();
		event.putInt("current", position / 1000);
		mEventEmitter.receiveEvent(getTargetId(), Events.PLAYING.toString(), event);
		handler.sendMessageDelayed(handler.obtainMessage(SHOW_PROGRESS), 1000 - (position % 1000));
	}

	private IPolyvOnPreparedListener2 mIPolyvOnPreparedListener2 = new IPolyvOnPreparedListener2() {

		@Override
		public void onPrepared() {
			WritableMap event = Arguments.createMap();
			event.putInt("duration", mVideoView.getDuration() / 1000);
			mEventEmitter.receiveEvent(getTargetId(), Events.LOADED.toString(), event);
		}
	};

	private IPolyvOnPlayPauseListener mIPolyvOnPlayPauseListener = new IPolyvOnPlayPauseListener() {

		@Override
		public void onPause() {
			handler.removeMessages(SHOW_PROGRESS);
			mEventEmitter.receiveEvent(getTargetId(), Events.PAUSED.toString(), Arguments.createMap());
		}

		@Override
		public void onPlay() {
			WritableMap event = Arguments.createMap();
			event.putInt("current", mVideoView.getCurrentPosition() / 1000);
			mEventEmitter.receiveEvent(getTargetId(), Events.PLAYING.toString(), event);

			handler.sendEmptyMessage(SHOW_PROGRESS);
		}

		@Override
		public void onCompletion() {
			handler.removeMessages(SHOW_PROGRESS);
		}
	};

	private IPolyvOnInfoListener2 mIPolyvOnInfoListener2 = new IPolyvOnInfoListener2() {
		@Override
		public boolean onInfo(int what, int extra) {
			 switch (what){
			 	case PolyvMediaInfoType.MEDIA_INFO_BUFFERING_START:
			 	Log.i("polyv", "onBuffStart");
			 	break;
			 	case PolyvMediaInfoType.MEDIA_INFO_BUFFERING_END:
			 	Log.i("polyv", "onBuffEnd");
			 	break;
			 }

			 return true;
		}
	};

	private IPolyvOnVideoStatusListener mIPolyvOnVideoStatusListener = new IPolyvOnVideoStatusListener() {

		@Override
		public void onStatus(int status) {


			if (status < 60) {
				Log.i("polyv", "onErrorStatus");
			} else {
				Log.i("polyv", "onNormal");

			}
		}

	};

	private IPolyvOnCompletionListener2 mIPolyvOnCompletionListener2 = new IPolyvOnCompletionListener2() {

		 @Override
		 public void onCompletion() {
		 	Log.i("polyv", "onEndC");
		 	mEventEmitter.receiveEvent(getTargetId(), Events.STOP.toString(), Arguments.createMap());
		 }
	};

	private IPolyvOnVideoPlayErrorListener2 mIPolyvOnVideoPlayErrorListener2 = new IPolyvOnVideoPlayErrorListener2() {

		@Override
		public boolean onVideoPlayError(@PolyvPlayErrorReason.PlayErrorReason int playErrorReason) {
			Log.i("polyv", "onError");
			return true;
		}
	};

	private IPolyvOnErrorListener2 mIPolyvOnErrorListener2 = new IPolyvOnErrorListener2() {

		@Override
		public boolean onError() {
			Log.i("polyv", "onError2");
			return true;
		}
	};

	@Override
	public void onHostResume() {
		Log.i("polyv", "resume");
	 	mVideoView.resume();
	}

	@Override
	public void onHostPause() {
		Log.i("polyv", "pause");
	 	mVideoView.pause();
	}

	@Override
	public void onHostDestroy() {
		Log.i("polyv", "destory");
		mVideoView.stopPlayback();
	}

	public int getTargetId() {
		return mVideoView.getId();
	}
}