level = require 'level'
levelws = require 'level-ws'

db = levelws level "#{__dirname}/../db"

module.exports = 
  # get(id, callback)
  # Get metrics 
  # - id: metric's id 
  # - callback: the callback function, callback(err, data)
  get: (id, callback) ->
    rs = db.createReadStream()
    rs.on 'data', data ->
      [ ..., dataUsername, dataId, dataTimestamp ] = data.key.split ":"
      if username == dataUsername
        res.push 
          id: dataId
          timestamp: dataTimestamp
          value: data.value

    rs.on 'error', (err) -> callback err
    rs.on 'end', () ->
      callback null, res
    
  # save(id, metrics, callback)
  # Save given metrics 
  # - id: metric id
  # - metrics: an array of { timestamp, value }
  # - callback: the callback function
  save: (id, metrics, callback) -> 
    ws = db.createWriteStream()
    ws.on 'error', callback 
    ws.on 'close', callback 
    for metric in metrics 
      { timestamp, value } =  metric
      ws.write 
        key: "metrics:#{id}:#{timestamp}"
        value: value
    ws.end()
  
  remove: (id, metrics, callback) ->
    # Arrays of keys to be deleted
    keys = []

    rs = db.createKeyStream()
    rs.on 'error', (err) -> callback err
    rs.on 'data', (key) ->
      [ keyTable, dataUsername, dataId ] = data.key.split ":"

      if keyTable == 'metric' and dataId == id and username == dataUsername
        keys.push key

    # Deleting 
    rs.on 'end', () ->
      ws = db.createWriteStream({ type: 'del' })

      ws.on 'error', (err) -> callback err
      ws.on 'close', callback

      for key in keys
        ws.write
          key: key
      ws.end()

