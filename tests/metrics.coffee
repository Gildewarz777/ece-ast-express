{exec} = require 'child_process'
should = require 'should'
assert = require 'assert'

describe "metrics", () ->
  metrics = null
  before (next) ->
    exec "rm -rf #{__dirname}/../db/*", (err, stdout) ->
      db = require('../src/db')("#{__dirname}/../db/data")
      metrics = require('../src/metrics')(db)
      next err

  # Save metrics test
  it "save metrics", (next) ->
    ## Create dummy data to then get
    metrics.save '1', [
        timestamp:(new Date '2015-11-04 14:00 UTC').getTime(), value: 23
      ,
        timestamp:(new Date '2015-11-05 14:10 UTC').getTime(), value: 56
    ], "testGet", (err, data) ->
      return next err if err
      next()

  # Get metrics by id test
  it "get metrics by id", (next) ->
    metrics.getById '1', "testGet", (err, metrics) ->
      return next err if err
      # Check if there is 2 metrics
      assert.equal 2, metrics.length
  
      # Check if the first metric is correctly saved
      assert.equal 1, metrics[0].id
      assert.equal 23, metrics[0].value
      next()

  # Get metrics test
  it "get metrics", (next) ->
    metrics.get "testGet", (err, metrics) ->
      return next err if err
      # Check if there is 2 metrics
      assert.equal 2, metrics.length
      
      # Check if the second metric is correctly saved
      assert.equal 1, metrics[1].id
      assert.equal 56, metrics[1].value
      next()

  # Delete metrics test
  it "delete metrics", (next) ->
  ## Create dummy data to then delete
    metrics.save '1', [
        timestamp:(new Date '2015-11-04 14:00 UTC').getTime(), value: 23
      ,
        timestamp:(new Date '2015-11-05 14:10 UTC').getTime(), value: 56
    ], 'testDelete', (err, data) ->
      metrics.delete '1', 'testDelete', (err) ->
        return next err if err
        metrics.get "test", (err, data) ->
          return next err if err
          # Check if there is no metrics
          assert.equal 0, data.length
          next()

  # Delete metrics by username test
  it "delete metrics by username", (next) ->
    ## Create dummy data to then delete
    metrics.save '2', [
        timestamp:(new Date '2015-11-04 14:00 UTC').getTime(), value: 23
      ,
        timestamp:(new Date '2015-11-05 14:10 UTC').getTime(), value: 56
    ], 'testDeleteByUsername', (err, data) ->
      return next err if err
      metrics.deleteByUsername 'testDeleteByUsername', (err) ->
        return next err if err
        metrics.get "test", (err, data) ->
          return next err if err
          # Check if there is no metrics
          assert.equal 0, data.length
          next()