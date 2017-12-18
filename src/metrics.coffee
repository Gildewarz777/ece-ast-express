module.exports = (db) ->
  # get (callback)
  # Get metrics
  # - username: the user id
  # - callback: the callback function, callback(err, data)
  get: (username, callback) ->
    res = []
    rs = db.createReadStream()
    rs.on 'data', (data) ->
      [ ..., dataUsername, dataId, dataTimestamp ] = data.key.split ":"
      if username == dataUsername
        res.push 
          id: dataId
          timestamp: dataTimestamp
          value: data.value
    rs.on 'error', (err) -> callback err
    rs.on 'end', () ->
      callback null, res

  # getById (id, callback)
  # Get given metrics
  # - id: metric's id
  # - username: the user id
  # - callback: the callback function, callback(err, data)
  getById: (id, username, callback) ->
    res = []
    rs = db.createReadStream()
    rs.on 'data', (data) ->
      [ ..., dataUsername, dataId, dataTimestamp ] = data.key.split ":"
      if dataId == id and username == dataUsername
        res.push 
          id: dataId
          timestamp: dataTimestamp
          value: data.value

    rs.on 'error', (err) -> callback err
    rs.on 'end', () ->
      callback null, res


  # save (id, metrics, callback)
  # Save given metrics
  # - id: metric id
  # - metrics: an array of { timestamp, value }
  # - username: the user id
  # - callback: the callback function
  save: (id, metrics, username, callback) ->
    ws = db.createWriteStream()
    ws.on 'error', (err) -> callback err
    ws.on 'close', callback
    for metric in metrics
      { timestamp, value } = metric
      ws.write 
        key: "metric:#{username}:#{id}:#{timestamp}"
        value: value
    ws.end()
  
  # deleteById (id, callback)
  # Delete given metrics
  # - id: metric id
  # - username: the user id
  # - callback: the callback function
  delete: (id, username, callback) ->
    keys = []
    rs = db.createKeyStream()
    rs.on 'error', (err) -> callback err
    rs.on 'data', (key) ->
      [ keyTable, dataUsername, dataId ] = key.split ":"
      if keyTable == 'metric' and dataId == id and username == dataUsername
        keys.push key

    rs.on 'end', () ->
      ws = db.createWriteStream
        type: 'del'
      ws.on 'error', (err) -> callback err
      ws.on 'close', callback

      for key in keys
        ws.write
          key: key
      ws.end()

  # deleteByUsername (username, callback)
  # Delete given metrics
  # - username: the user id
  # - callback: the callback function
  deleteByUsername: (username, callback) ->
    keys = []

    rs = db.createKeyStream()
    rs.on 'error', (err) -> callback err
    rs.on 'data', (key) ->
      [ keyTable, dataUsername ] = key.split ":"
      if keyTable == 'metric' and username == dataUsername
        keys.push key

    rs.on 'end', () ->
      ws = db.createWriteStream
        type: 'del'
      ws.on 'error', (err) -> callback err
      ws.on 'close', callback

      for key in keys
        ws.write
          key: key
      ws.end()