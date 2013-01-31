require.define 'soundmanager/utils': (exports, require, module)->
    noop = ->

    module.exports =
        'noop' : noop


#Make it safe to do console.log() always.
((con) ->
    dummy = ->
    methods = [
        'assert'
        'count'
        'debug'
        'dir'
        'dirxml'
        'error'
        'exception'
        'group'
        'groupCollapsed'
        'groupEnd'
        'info'
        'log'
        'markTimeline'
        'profile'
        'profileEnd'
        'time'
        'timeEnd'
        'trace'
        'warn'
    ]

    (con[method] = con[method] or dummy) for method in methods
    return
)(window.console = window.console or {})