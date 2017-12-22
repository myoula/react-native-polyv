import {
	NativeModules,
	NativeAppEventEmitter
} from 'react-native';

const Polyv = NativeModules.Polyv;

module.exports = {
	init: function(appId, appKey, appSecret) {
		Polyv.init(appId, appKey, appSecret);
	},
	download: function(vid, level) {
		Polyv.download(vid, level);
	},
	start: function(vid) {
		Polyv.start(vid);
	},
	stop: function(vid) {
		Polyv.stop(vid);
	},
	delete: function(vid) {
		Polyv.delete(vid);
	},
	clean: function() {
		Polyv.clean();
	},
	addListener: function(callback) {
		return NativeAppEventEmitter.addListener('Download', callback);
	},
	Player: require('./Player'),
	LivePlayer: require('./Live')
};