assert       = require('assert')
path         = require('path')
request      = require('request')
API          = require('./browser_api')
MessagePeer  = require('../shared/message_peer')
JSDOMWrapper = require('./jsdom_wrapper')

# TODO: reintroduce these
#@syncCmds = []
#@cmdBuffer = []
class Browser
    # TODO: default url parameter
    constructor : (browserID, url) ->
        @id = browserID
        # The API we expose to all connected clients.
        @API = new API(this)
        # JSDOMWrapper adds advice to JSDOM.
        @wrapper = new JSDOMWrapper(this)
        # The name of the property that holds a DOM node's ID.
        @idProp = @wrapper.nodes.propName
        # Each advice function emits the DOMUpdate event, which we want to echo
        # to all connected clients.
        @wrapper.on 'DOMUpdate', @broadcastUpdate
        # This is the wrapped JSDOM instance
        @jsdom = @wrapper.jsdom
        # Array of clients waiting for page to load.
        @connQ = []
        # Array of currently connected Socket.io clients.
        @clients = []
        @load url if url?

    # For now, source is always a URL. TODO: accept file path
    load : (source) ->
        console.log "About to make request to: #{source}"
        #TODO: should I be using window.location and let JSDOM's resourcemanager do the work?
        #      I think this will work on files or URLs
        request {uri: source}, (err, response, body) =>
            console.log "Got result from request"
            if err
                console.log "Error with request"
                throw new Error(err)
            console.log "Request succeeded"
            @document = @jsdom.jsdom(body)
            @document[@idProp] = '#document'
            @window = @document.createWindow()
            @clearConnQ()

    # TODO: should we defer creating MessagePeers til here? If we make them
    # earlier, we'll hook up .on('message') before the client is really
    # connected.
    clearConnQ : ->
        console.log "Clearing connQ"
        syncCmds = @docToInstructions()
        for client in @connQ
            console.log "Syncing a client"
            client.send(syncCmds)
            @clients.push(client)
        @connQ = []

    broadcastUpdate : (params) =>
        msg = MessagePeer.createMessage('DOMUpdate', params)
        cmd = JSON.stringify(msg)
        for client in @clients
            client.sendJSON(cmd)

    addClient : (sock) ->
        console.log "Browser#addClient"
        client = new MessagePeer(sock, @API)
        if !@document?
            console.log "Queuing client"
            @connQ.push(client)
            return false
        syncCmds = @docToInstructions()
        client.send(syncCmds)
        client.sock.on 'disconnect', =>
            @removeClient(client)
        @clients.push(client)
        return true

    removeClient : (client) ->
        @clients = (c for c in @clients when c != client)

    docToInstructions : ->
        if !@document?
            throw new Error "Called docToInstructions with empty document"
        syncCmds = [MessagePeer.createMessage('clear')]

        dfs = (node, filter, visit) ->
            if filter(node)
                visit(node)
                if node.hasChildNodes()
                    for childNode in node.childNodes
                        dfs(childNode, filter, visit)
        filter = (node) ->
            name = node.tagName
            # TODO FIXME
            # Actually, do I need to create these, but just without src?
            # Programmer could use DOM methods to manipulate these nodes,
            # which don't exist on the client.
            if name? && (name == 'SCRIPT')
                console.log('skipping script tag.')
                return false
            return true
        self = this
        dfs @document, filter, (node) ->
            typeStr = self.nodeTypeToString[node.nodeType]
            method = '_cmdsFor' + typeStr
            if (typeof self[method] != 'function')
                console.log "Can't create instructions for #{typeStr}"
                return
            cmds = self[method](node); # returns an array of cmds
            if (cmds != undefined)
                syncCmds = syncCmds.concat(cmds)
        return syncCmds

    _cmdsForDocument : (node) ->
        [MessagePeer.createMessage 'assignDocumentEnvID', '#document']

    _cmdsForElement : (node) ->
        cmds = []
        cmds.push MessagePeer.createMessage 'DOMUpdate',
            targetID : '#document'
            rvID : node[@idProp],
            method : 'createElement'
            args : [node.tagName]
        if node.attributes && (node.attributes.length > 0)
            for attr in node.attributes
                cmds.push MessagePeer.createMessage 'DOMUpdate',
                    targetID : node[@idProp]
                    rvID : null
                    method : 'setAttribute',
                    args : [attr.name, attr.value]

        cmds.push MessagePeer.createMessage 'DOMUpdate',
            targetID : node.parentNode[@idProp]
            rvID : null
            method : 'appendChild'
            args : [node[@idProp]]
        return cmds

    _cmdsForText : (node) ->
        cmds = []
        cmds.push MessagePeer.createMessage 'DOMUpdate',
            targetID : '#document'
            rvID : node[@idProp]
            method :'createTextNode'
            args : [node.data]
        if node.attributes && node.attributes.length > 0
            for attr in node.attributes
                cmds.push MessagePeer.createMessage 'DOMUpdate'
                    targetID : node[@idProp]
                    rvID : null
                    method : 'setAttribute'
                    args : [attr.name, attr.value]
        cmds.push MessagePeer.createMessage 'DOMUpdate',
            targetID : node.parentNode[@idProp]
            rvID : null
            method : 'appendChild'
            args : [node[@idProp]]
        return cmds

    nodeTypeToString : [0,
        'Element',                 #1
        'Attribute',               #2
        'Text',                    #3
        'CData_Section',           #4
        'Entity_Reference',        #5
        'Entity',                  #6
        'Processing_Instruction',  #7
        'Comment',                 #8
        'Document',                #9
        'Docment_Type',            #10
        'Document_Fragment',       #11
        'Notation'                 #12
    ]

module.exports = Browser