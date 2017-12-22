# react-native-polyv
保利威视 点播和直播sdk 2.0

import * as Polyv from 'react-native-polyv';

Polyv.init(appId, appKey, secretKey);
----------------------------------------
import {LivePlayer} from 'react-native-polyv';
<LivePlayer source={{channel: 'xxx'}} ref='player'
					onLoaded={(data) => {
						
					}}

					onPlaying={(data) => {
						
					}}

					onStop={(data) => {
						
					}}

					onError={() => {
						
					}}

					onReceiveMessage={(data) => {

					}}

/>

this.refs['player'].message('xxxx')

----------------------------------------
import {Player} from 'react-native-polyv';

<Player ref='player' source={{vid: 'xxxx'}} 
					onLoading={(data) => {

					}}

					onLoaded={(data) => {
						
					}}

					onPlaying={(data) => {
						console.info(data);
						this.setState({buf: false, played: true, current: data.current})
					}}

					onPaused={(data) => {
						
					}}  

					onStop={(data) => {
						
					}}

					onError={() => {
						
					}}
/>
