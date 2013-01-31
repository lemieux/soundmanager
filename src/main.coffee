###
    SoundManager 0.0.1

    Author : Marc-Antoine Lemieux
    URL : http://marcantoinelemieux.com
###

require.define 'soundmanager': (exports, require, module)->
    Utils = require 'soundmanager/utils'
    module.exports = class SoundManager

        #initialize the audio context using the HTML5 AudioContext object if available.
        @audioContext: if AudioContext? then new AudioContext  else new webkitAudioContext

        constructor : ->
            @bufferCache = {}
            @activeSources = []
            @audioContext = SoundManager.audioContext
            @playing = no


        ###*
         * Tells if a song has already been loaded in cache
         * @param  {string}  sound url to the sound file
         * @return {Boolean} true if it has been load, false if not
        ###
        isLoaded: (sound) =>
            if @bufferCache[sound] then yes else no

        ###*
         * Loads a sound file from its url
         * @param  {string} sound   url to the sound file
         * @param  {function} success   function to be called when loading is successful - will return the value of the sound parameter (optional)
         * @param  {function} error   function to be called when loading throws an error - will return the value of the sound parameter (optional)
         * @return
        ###
        load : (sound, success = Utils.noop, error = Utils.noop) =>

            if @isLoaded sound
                success sound
                return

            console.info "SoundManager : loading #{sound}"

            request = new XMLHttpRequest
            request.open 'GET', sound, true
            request.responseType = 'arraybuffer'

            #checking for errors
            request.onreadystatechange = ->
                if request.readyState isnt 4
                    return
                if request.status isnt 200
                    error sound
                return

            #loading the buffer
            request.onload = (e) =>
                @audioContext.decodeAudioData request.response, (buffer)=>
                    @bufferCache[sound] = buffer
                    success sound
                    return
                return

            #sending the request
            request.send()
            return


        ###*
         * Loads multiple sound files from their url
         * @param  {array} sounds  array of sound url
         * @param  {function} success =  function to be called when loading is successful - will return an array with all sound url that had been loaded successfully (optional)
         * @param  {function} error   =  function to be called when loading throws an error - will return an array with all sound url that threw an error (optional)
        ###
        loadMultiple : (sounds, success = Utils.noop, error = Utils.noop) =>
            if typeof(sounds) isnt Array
                error()
                return

            #keeping track of all the successful sound load
            sucesses = []
            #keeping track of every sound that threw an error
            errors = []


            successCallback = (sound) =>
                sucesses.push sound
                if sucesses.length + errors.length is sounds.length
                    success sucesses
                if errors.length > 0
                    error errors
                return

            errorCallback = (sound) =>
                errors.push sound
                if sucesses.length + errors.length is sounds.length
                    error errors
                if sucesses.length > 0
                    success sucesses
                return

            @load(sound, successCallback, errorCallback) for sound in sounds
            return

        ###*
         * Returns the buffer matching the sound url
         * @param  {string}   sound    url to the sound file
         * @param  {Function} callback function returning the buffer. The buffer will be loaded if it wasn't already.
        ###
        getBuffer : (sound, callback) =>
            if @isLoaded sound
                callback @bufferCache[sound]
                return

            successCallback = =>
                @getBuffer sound, callback
                return

            errorCallback = =>
                callback null
                return

            @load sound, successCallback, errorCallback
            return

        ###*
         * Play a sound
         * @param  {string} sound   url to the sound file
         * @param  {int} timing  number of seconds before the sound is played (default = 0 (now))
         * @param  {Function} success function to be called when the sound is queued
         * @param  {Function} error function to be called if an error occurs
         * @return {AudioNode} returns the AudioNode that will play the sound. It might not be fully initialized when returned but it can be connected to other nodes.
        ###
        play : (sound, timing = 0, success = Utils.noop, error = Utils.noop) =>
            source = @audioContext.createBufferSource()
            @getBuffer sound, (buffer) =>
                if buffer
                    console.info "SoundManager : playing #{sound}"
                    @playing = yes
                    source.buffer = buffer
                    source.connect @audioContext.destination
                    source.noteOn timing
                    @activeSources.push source
                    return
                error sound
                return
            return source


        ###*
         * Stops the current playback
        ###
        stop: =>
            if @playing
                console.info "SoundManager : stopping"
                for source in @activeSources
                    source.noteOff 0
                    source.disconnect()
                @activeSources = []
                @playing = no


        ###*
         * Returns audioContext's currentTime
         * @return {double} audioContext's currentTime
        ###
        getCurrentTime: =>
            @audioContext.currentTime
