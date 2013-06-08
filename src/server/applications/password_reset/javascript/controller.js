(function() {
  var CBPasswordReset;

  CBPasswordReset = angular.module("CBPasswordReset", []);

  CBPasswordReset.controller("ResetCtrl", function($scope) {
    CloudBrowser.auth.getResetEmail(function(userEmail) {
      return $scope.$apply(function() {
        return $scope.email = userEmail.split("@")[0];
      });
    });
    $scope.password = null;
    $scope.vpassword = null;
    $scope.isDisabled = false;
    $scope.passwordError = null;
    $scope.passwordSuccess = null;
    $scope.$watch("password", function() {
      $scope.passwordError = null;
      $scope.passwordSuccess = null;
      return $scope.isDisabled = false;
    });
    return $scope.reset = function() {
      $scope.isDisabled = true;
      if (!($scope.password != null) || !/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\da-zA-Z])\S{8,15}$/.test($scope.password)) {
        return $scope.passwordError = "Password must be have a length between 8 - 15 characters," + " must contain atleast 1 uppercase, 1 lowercase, 1 digit and 1 special character." + " Spaces are not allowed.";
      } else {
        return CloudBrowser.auth.resetPassword($scope.password, function(success) {
          return $scope.$apply(function() {
            if (success) {
              $scope.passwordSuccess = "The password has been successfully reset";
            } else {
              $scope.passwordError = "Password can not be changed as the reset link is invalid.";
            }
            return $scope.isDisabled = false;
          });
        });
      }
    };
  });

}).call(this);
