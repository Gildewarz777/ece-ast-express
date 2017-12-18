module.exports = (db) ->
  # get (username, callback)
  # Get user informations
  # - callback: the callback function, callback(err, data)
  get: (username, callback) ->
    db.get "user:#{username}", (err, data) ->
      return callback err if err
      [ password, email ] = data.split ":"
      result = 
        username: username
        password: password
        email: email
      callback null, result

  # save (username, password, email, callback)
  # Save user
  # - username: user name
  # - password: user password
  # - email: user mail
  # - callback: the callback function
  save: (username, password, email, callback) ->
    ws = db.createWriteStream()
    ws.on 'error', (err) -> callback err
    ws.on 'close', callback

    ws.write
      key: "user:#{username}"
      value: "#{password}:#{email}"
    ws.end()

  # remove (username, callback)
  # Delete given user
  # - username: the user id
  # - callback: the callback function
  remove: (username, callback) ->
    ws = db.createWriteStream
      type: 'del'
    ws.on 'error', (err) -> callback err
    ws.on 'close', callback

    ws.write
      key: "user:#{username}"
    ws.end()

    metrics = require('./metrics')(db)

    metrics.deleteByUsername username, (err) ->
      callback err if err