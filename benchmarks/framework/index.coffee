Path         = require('path')
ClientMaster = require('./client_master')
Server       = require('./server')
Exec         = require('child_process').exec

# TODO: this should have createClient to go with createServer.
exports.Client = require('./client')

exports.createServer = (opts, callback) ->
    server = new Server(opts)
    if callback?
        server.once 'ready', () ->
            callback(server)
    return server

exports.createClients = (numClients, numClientsPerProcess, callbackInterval, callback, sendMessages) ->
    master = new ClientMaster(numClients, sendMessages) #TODO: numClientsPerProcess
    master.once 'start', () ->
        if callback? && callbackInterval?
            setInterval () ->
                callback(master.results)
            , callbackInterval
    return master

exports.gnuPlot = (script, callback) ->
    cwd = Path.dirname(module.parent.filename)
    Exec "gnuplot #{script}", {cwd : cwd}, (err, stdout) ->
        throw err if err
        callback() if callback