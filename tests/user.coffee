{exec} = require 'child_process'
should = require 'should'
assert = require 'assert'

describe "user", () ->
  user = null
  before (next) ->
    exec "rm -rf #{__dirname}/../db/*", (err, stdout) ->
      db = require('../src/db')("#{__dirname}/../db/data")
      user = require('../src/user')(db)
      next err
  
  # Save user test
  it "save user", (next) ->
    # Create dummy user data
    user.save 'test', 'test', 'test@test.fr', (err, data) ->
      return next err if err
      next()

  # Get user test
  it "get user", (next) ->
    user.get 'test', (err, data) ->
      return next err if err
      # Test user data
      assert.equal 'test', data.username
      assert.equal 'test', data.password
      assert.equal 'test@test.fr', data.email
      next()

  # Remove user test
  it "remove user", (next) ->
    user.remove 'test', (err) ->
      return next err if err
      # Test if user is correctly deleted
      user.get 'test', (err, data) ->
        should.exist err
        next()

  after (next) ->
    # Exit the process: need to close  connection with db in order to make it avilable for the next one