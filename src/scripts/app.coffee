angular.module "candidate-stats", [
  "ngTouch"
  "templates"
]
.controller "StatsController", ($scope, $http) ->
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
