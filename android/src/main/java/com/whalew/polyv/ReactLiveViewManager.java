package com.whalew.polyv;

import java.util.Map;
import javax.annotation.Nullable;

import android.os.Build;
import android.util.Log;
import android.support.annotation.NonNull;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.events.RCTEventEmitter;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;

import com.easefun.polyvsdk.live.video.PolyvLiveVideoView;
import com.easefun.polyvsdk.live.video.PolyvLiveVideoViewListener;
import com.easefun.polyvsdk.live.video.PolyvLivePlayErrorReason;
import com.easefun.polyvsdk.live.chat.PolyvChatManager;
import com.easefun.polyvsdk.live.chat.PolyvChatMessage;
import com.easefun.polyvsdk.live.chat.playback.api.PolyvLive_Status;
import com.easefun.polyvsdk.live.chat.playback.api.listener.PolyvLive_StatusNorListener;

public class ReactLiveViewManager extends SimpleViewManager<PolyvLiveVideoView>{

	public static final String REACT_CLASS = "RCTLive";

	private RCTEventEmitter mEventEmitter;
	private ThemedReactContext reactContext = null;
	private PolyvLiveVideoView mVideoView = null;

	private PolyvLive_Status live_status;
	private PolyvChatManager chatManager;
	private String userId = "c9dfafc016";
	private String channelId;

	public enum Events {
		LOADED("onLoaded"),
		PLAYING("onPlaying"),
		RECEIVED("onReceiveMessage"),
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

	@ReactProp(name = "source")
	public void setSource(PolyvLiveVideoView mVideoView, ReadableMap source) {
		channelId = source.getString("channel");
		Log.i("polyv", channelId);

		String chatUserId = Build.SERIAL;
		String nickName = "游客" + Build.SERIAL;
		chatManager.login(chatUserId, channelId, nickName);
		mVideoView.setLivePlay(userId, channelId, false);
	}

	@ReactProp(name = "message")
	public void setMessage(PolyvLiveVideoView mVideoView, String message) {
		final PolyvChatMessage msg = new PolyvChatMessage(message);
		chatManager.sendChatMessage(msg);
	}

	@Override
	protected PolyvLiveVideoView createViewInstance(ThemedReactContext reactContext) {

		this.reactContext = reactContext;
		

		mEventEmitter = reactContext.getJSModule(RCTEventEmitter.class);
		mVideoView = new PolyvLiveVideoView(reactContext.getApplicationContext());

		mVideoView.setOpenWait(true);
        mVideoView.setOpenPreload(true, 2);

		mVideoView.setOnPreparedListener(mOnPreparedListener);
		mVideoView.setOnVideoPlayErrorListener(mOnVideoPlayErrorListener);
		mVideoView.setOnErrorListener(mOnErrorListener);
		mVideoView.setOnWillPlayWaittingListener(mOnWillPlayWaittingListener);
		mVideoView.setOnNoLiveAtPresentListener(mOnNoLiveAtPresentListener);

		chatManager = new PolyvChatManager();
		chatManager.setOnChatManagerListener(mChatManagerListener);
		return mVideoView;
	}

	@Override
    public void onDropViewInstance(PolyvLiveVideoView view) {
		super.onDropViewInstance(view);

		if (live_status != null) {
			live_status.shutdownSchedule();
		}

		chatManager.disconnect();
		
		if (mVideoView != null) {
			mVideoView.destroy();
		}
    }

	private PolyvChatManager.ChatManagerListener mChatManagerListener = new PolyvChatManager.ChatManagerListener() {

		@Override
		public void connectStatus(PolyvChatManager.ConnectStatus connect_status) {
		
		}

		@Override
		public void receiveChatMessage(PolyvChatMessage chatMessage) {
			WritableMap event = Arguments.createMap();
			event.putString("messageType", "PLVChatMessageTypeSpeak");
			mEventEmitter.receiveEvent(getTargetId(), Events.RECEIVED.toString(), event);
		}
	};

	private PolyvLiveVideoViewListener.OnPreparedListener mOnPreparedListener = new PolyvLiveVideoViewListener.OnPreparedListener() {

		@Override
		public void onPrepared() {
			Log.i("polyv", "LOADED");
			mEventEmitter.receiveEvent(getTargetId(), Events.LOADED.toString(), Arguments.createMap());
		}
	};

	private PolyvLiveVideoViewListener.OnVideoPlayErrorListener mOnVideoPlayErrorListener = new PolyvLiveVideoViewListener.OnVideoPlayErrorListener() {

		@Override
		public void onVideoPlayError(@NonNull PolyvLivePlayErrorReason errorReason) {
			Log.i("polyv", "ERROR1");
			mEventEmitter.receiveEvent(getTargetId(), Events.ERROR.toString(), Arguments.createMap());
		}
	};

	private PolyvLiveVideoViewListener.OnErrorListener mOnErrorListener = new PolyvLiveVideoViewListener.OnErrorListener() {

		@Override
		public void onError() {
			Log.i("polyv", "ERROR");
			mEventEmitter.receiveEvent(getTargetId(), Events.ERROR.toString(), Arguments.createMap());
		}
	};

	private PolyvLiveVideoViewListener.OnWillPlayWaittingListener mOnWillPlayWaittingListener = new PolyvLiveVideoViewListener.OnWillPlayWaittingListener() {

		 @Override
		 public void onWillPlayWaitting(boolean isCoverImage) {

		 	Log.i("polyv", "NO LIVE");
		 	mEventEmitter.receiveEvent(getTargetId(), Events.STOP.toString(), Arguments.createMap());
		 	checkStatus();
		 }
	};

	private PolyvLiveVideoViewListener.OnNoLiveAtPresentListener mOnNoLiveAtPresentListener = new PolyvLiveVideoViewListener.OnNoLiveAtPresentListener() {

		@Override
		public void onNoLiveAtPresent() {
			Log.i("polyv", "NO LIVE1");
			mEventEmitter.receiveEvent(getTargetId(), Events.STOP.toString(), Arguments.createMap());
			checkStatus();
		}
	};

	private void checkStatus() {
		Log.i("polyv", "INIT CHECK");
		if (live_status == null) live_status = new PolyvLive_Status();
		live_status.shutdownSchedule();

		live_status.getLive_Status(channelId, 6000, 4000, new PolyvLive_StatusNorListener() {

			@Override
			public void success(boolean isLiving, final boolean isPPTLive) {
				Log.i("polyv", "LIVE");
				if (isLiving) {
					live_status.shutdownSchedule();
					mEventEmitter.receiveEvent(getTargetId(), Events.PLAYING.toString(), Arguments.createMap());
					mVideoView.setLivePlay(userId, channelId, false);
				}
			}

			@Override
			public void fail(String failTips, int code) {
				Log.i("polyv", "ERROR");
			}

		});
	}

	public int getTargetId() {
		return mVideoView.getId();
	}

}