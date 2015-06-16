angular.module "candidate-stats", [
  "ngTouch"
  "templates"
]
.controller "StatsController", ($scope, $http) ->
  $http.get "//54.77.4.249:8000/stats"
    .success (data) ->
      $scope.stats = data
    .error (data, status, headers, config) ->
      return

  $http.get "//54.77.4.249:8000/header"
    .success (data) ->
      $scope.header = data.statistik
      $scope.last_update = data.last_update.replace " ", "T"
      $scope.mandates = data.stats.mandates
    .error (data, status, headers, config) ->
      return
