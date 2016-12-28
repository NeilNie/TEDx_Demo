/**
 * Copyright 2016 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Transport from 'Tone/core/Transport'
import Loop from 'Tone/event/Loop'
import Background from 'music/Background'
import Time from 'Tone/type/Time'
import Fill from 'music/Fill'
import Config from 'Config'
import Master from 'Tone/core/Master'
import MusicPosition from 'music/Position'

Transport.bpm.value = 128

export default class Music{
	constructor(){

		this._bgMusic = new Background()

		this._fill = new Fill()

	}

	start(){
		let startTime = Transport.now() + 0.7
		Transport.start(startTime)
		this._bgMusic.start(startTime)
		Master.mute = false
		return startTime
	}

	stop(){
		this._bgMusic.stop()
		this._fill.stop()
		// Master.volume.rampTo(-Infinity, 2)
		Transport.stop()
		Transport.clear(0)
	}

	fill(){
		if (Transport.state === 'started'){
			this._bgMusic.fill()
			this._fill.fill()
		}
	}

	endFill(){
		if (Transport.state === 'started'){
			this._bgMusic.fillEnd()
			this._fill.fillEnd()
		}
		return new Promise((done) => {
			Transport.scheduleOnce( (time) => {
				done(time)
			}, `@${Config.quantizeLevel}`)
		})
	}

	/**
	 * load the text line from the server
	 */
	loadLine(labels){
		return this._speaker.loadLine(labels)
	}

	end(){
		return this._bgMusic.end()
	}
	 
}