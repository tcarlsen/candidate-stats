angular.module "candidate-stats", [
  "ngTouch"
  "templates"
]
.controller "StatsController", ($scope, $http) ->
  socket = io "http://hosting-docker-fv15-ws-1802147016.eu-west-1.elb.amazonaws.com"
  allowPopup = true

  $scope.refresh = ->
    document.location.reload(true)

  $scope.terminate = ->
    $scope.showPopup = false

    allowPopup = false

  $http.get "//fv15api.bemit.dk/stats"
    .success (data) ->
      $scope.stats = data
    .error (data, status, headers, config) ->
      return

  $http.get "//fv15api.bemit.dk/header"
    .success (data) ->
      $scope.header = data.statistik
      $scope.last_update = data.last_update.replace " ", "T"
      $scope.mandates = data.stats.mandates
    .error (data, status, headers, config) ->
      return

  socket.on "data_updated", ->
    if allowPopup
      $scope.$apply -> $scope.showPopup = true
