CBAdmin         = angular.module("CBAdmin", [])
Util            = require('util')
baseURL = "http://" + config.domain + ":" + config.port
CBAdmin.controller "AppCtrl", ($scope, $timeout) ->
    $scope.domain = config.domain
    $scope.port = config.port
    # Use node emit
    $scope.getApps = () ->
        $timeout ->
            $scope.apps = server.applicationManager.applications
            $scope.getApps()
            null        # avoid memory leak, see https://github.com/angular/angular.js/issues/1522#issuecomment-15921753
        , 100
    $scope.getApps()
    $scope.click = (mountPoint) ->
        bserver.redirect(baseURL + mountPoint)
    $scope.deleteVB = (mountPoint, browserID) ->
        vb = server.applicationManager.find(mountPoint).browsers.find(browserID)
        server.applicationManager.find(mountPoint).browsers.close(vb)
