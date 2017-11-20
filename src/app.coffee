express = require 'express'
bodyparser = require 'body-parser'

metrics = require './metrics'

app = express()

app.set 'port', '8888'
app.set 'views', "#{__dirname}/../views"
app.set 'view engine', 'pug'

app.use bodyparser.json()
app.use bodyparser.urlencoded()

app.use '/', express.static "#{__dirname}/../public"

app.get '/', (req, res) ->
  res.render 'index', 
    text: "Hello world !"

app.get '/hello/:name', (req, res) ->
  res.send "Hello #{req.params.name}"
  
app.get '/metrics.json', (req, res) -> 
  metrics.get (err, data) ->
    throw next err if err
    res.status(200).json data
    
app.post '/metrics.json/:id', (req, res) -> 
  metrics.save req.params.id, req.body, (err) ->
    throw next err if err 
    res.status(200).send 'metrics saved'

app.delete '/metrics.json/:id', (req, res) ->
  metrics.remove req.params.id, req.body, (err) ->
    throw next err if err
    res.status(200).send 'metrics removed'

app.listen app.get('port'), () ->
  console.log "Server listening on #{app.get 'port'} !"
