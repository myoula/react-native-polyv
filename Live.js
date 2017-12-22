import React, { Component } from 'react';

import {
	View,
	requireNativeComponent
} from 'react-native';

const PropTypes = require('prop-types');

class Live extends Component {

	constructor(props) {
		super(props);

		this._assignRoot = this._assignRoot.bind(this);
		this.message = this.message.bind(this);
		this._onLoaded = this._onLoaded.bind(this);
		this._onStop = this._onStop.bind(this);
		this._onError = this._onError.bind(this);
		this._onPlaying = this._onPlaying.bind(this);
		this._onReceiveMessage = this._onReceiveMessage.bind(this);
	}

	_assignRoot(component) {
		this._root = component
	}

	setNativeProps(nativeProps) {
		this._root.setNativeProps(nativeProps)
	}

	message(message) {
		this.setNativeProps({ message: message })
	}

	_onLoaded(event) {
		this.props.onLoaded && this.props.onLoaded(event.nativeEvent);
	}

	_onPlaying(event) {
		this.props.onPlaying && this.props.onPlaying(event.nativeEvent);
	}

	_onStop(event) {
		this.props.onStop && this.props.onStop(event.nativeEvent);
	}

	_onError(event) {
		this.props.onError && this.props.onError(event.nativeEvent);
	}

	_onReceiveMessage(event) {
		this.props.onReceiveMessage && this.props.onReceiveMessage(event.nativeEvent);
	}

	render() {

		const nativeProps = Object.assign({}, this.props);

		return (
			<RCTLive ref={this._assignRoot}  {...nativeProps}/>
		);
	}
}

Live.propTypes = {
	source: PropTypes.shape({
		channel: PropTypes.string.isRequired
	}),
	message: PropTypes.string,
	onLoaded: PropTypes.func,
	onStop: PropTypes.func,
	onError: PropTypes.func,
	onPlaying: PropTypes.func,
	onReceiveMessage: PropTypes.func
};

const RCTLive = requireNativeComponent('RCTLive', Live, {
	nativeOnly: {
		testID: true,
		accessibilityComponentType: true,
		renderToHardwareTextureAndroid: true,
		accessibilityLabel: true,
		accessibilityLiveRegion: true,
		importantForAccessibility: true,
		onLayout: true,
		nativeID: true,
	}

});

module.exports = Live;