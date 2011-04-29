#!/usr/bin/env node

// Module imports
var fs             = require('fs'),
    connect        = require('connect'),
    assert         = require('assert'),
    path           = require('path'),
    BrowserManager = require('./browser_manager'),
    Browserify     = require('browserify'),
    ClientChannel  = require('./client_channel');

// Server variables
var basePagePath = './base.html',
    browsers = new BrowserManager(),
    basePage = fs.readFileSync(basePagePath, 'utf8'),
    //TODO: switch to Redis for session store.
    memoryStore = new connect.session.MemoryStore({
        reapInterval: 60000,
        maxAge: 60000 * 2
    });

// The front-end HTTP server
var server = connect.createServer(
    Browserify({
        base : path.join(__dirname, '../client/'),
        mount : '/browserify.js'
    }),
    connect.logger(),
    connect.cookieParser(),
    connect.session({ store: memoryStore, secret: 'test' }),
    connect.router(routes)
);

// ClientChannel for handling Socket.IO connections
var clientChannel = new ClientChannel(server, browsers);

// Server helper functions
function returnBasePage (req, res, id) {
    res.writeHead(200, {'Content-type': 'text/html'});
    res.end(basePage.replace(/:BROWSER_ID:/, id));
};

function returnHTML (browser, res) {
    res.writeHead(200, {'Content-type': 'text/html'});
    res.end(browser.dumpHTML());
};

function send500error (res) {
    res.writeHead(500, {'Content-type': 'text/html'});
    res.end();
};

function routes (app) {
    //TODO: support sub-directories.
    app.get('/:source.html', function (req, res) {
        var sessionID = req.sessionID;
        browsers.lookup(sessionID, function (browser) {
            browser.load(req.params.source + '.html', function () {
                //TODO: Move this to return basepage immediately.
                //      I was getting an error about accessing the request
                //      after sending, so need to make sure we don't do that.
                returnBasePage(req, res, sessionID)
                console.log('BrowserInstance loaded.');
            });
        });
    });
};

function printStats () {
    console.log('Current Socket.io connections: ' +
                this.clientChannel.numCurrentUsers);
    console.log('Total Socket.io connections: ' +
                this.clientChannel.numConnections);
};

// Start up the front-end server.
server.listen(3000, function () {
    console.log('Server listening on port 3000.');
});


// Initialize the zombie server.
// TODO: Should this be in its own process?
var server = connect.createServer(
    //TODO: This should only accept connections from localhost.
    //      Might have to filter this myself based on req ip.
    //TODO: Should this server have support for sessions and cookies?
    //connect.cookieParser(),
    //connect.session({ store: memoryStore, secret: 'test' }),
    connect.router(function (app) {
        app.get('/:source.html', function (req, res) {
            var pagePath = path.join(process.cwd(), 'html', req.params.source + '.html');
            fs.readFile(pagePath, 'utf8', function (err, html) {
                if (err) {
                    throw new Error(err);
                }
                res.writeHead(200, {'Content-type': 'text/html',
                                    'Content-length': html.length});
                res.end(html);
            });
        });
    })
);
server.listen(3001, function () {
    console.log('Zombie server listening on port 3001.');
});