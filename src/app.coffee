express = require 'express'
bodyparser = require 'body-parser'
morgan = require 'morgan'
session = require 'express-session'
SessionStore = require('level-session-store')(session)

db = require('./db')("#{__dirname}/../db/data")
metrics = require('./metrics')(db)
user = require('./user')(db)

app = express()

server = require('http').Server(app)
io = require('socket.io')(server)

### MIDDLEWARES ###
# Logs generator middleware
logging_middleware = (req, res, next) ->
  # Write logs with username and requested url
  io.emit 'logs',
    username: if req.session.loggedIn then req.session.username else 'anonymous'
    url: req.url
  next()

# Centralize error handler
error_middleware = (err, req, res, next) ->
  # formulate an error response here
  res.status(500).send 'Internal error'

### SERVER PARAMS ###
app.set 'port', 8888
app.set 'views', "#{__dirname}/../views"
app.set 'view engine', 'pug'

app.use '/', express.static "#{__dirname}/../public"

app.use bodyparser.json()
app.use bodyparser.urlencoded()
app.use morgan 'dev'
app.use session
  secret: "simple secret"
  store: new SessionStore '../db/sessions'
  resave: true
  saveUninitialized: true


### ROUTES ###
# Logging: get
# Logging screen
app.get '/logging', (req, res) ->
  res.render 'logging'

# Authentification check: If not already logged in, redirect to /login
authCheck = (req, res, next) ->
  unless req.session.loggedIn == true
    res.redirect '/login'
  else 
    next()

# Login: get
# Get the login page
app.get '/login', (req, res) ->
  res.render 'login'

# Login: post
# If a username and a password are passed, log in the user
app.post '/login', (req, res, next) ->
  {username, password} = req.body
  user.get username, (err, user) ->
    if err
      res.redirect '/login'

    else
      req.session ?= {}
      req.session.loggedIn = true
      req.session.username = user.username
      res.redirect '/'

# Signup: get
# Get the signup page
app.get '/signup', (req, res) ->
  res.render 'signup'

# Signup: post
# Sign in a user with username, password, email passed as input.
app.post '/signup', (req, res, next) ->
  {username, password, email} = req.body
  user.save username, password, email, (err) ->
    next( new Error 'Signup error' ) if err
    else
      res.redirect '/login'

# Logout: get
# Delete session infos and redirect to /login
app.get '/logout', authCheck, (req, res) ->
  delete req.session.loggedIn
  delete req.session.username
  res.redirect '/login'

# Main route: get
# Display index page
app.get '/', authCheck, (req, res) ->
  res.render 'index', name: req.session.username

# Hello world: get
# Test route
app.get '/hello/:name', (req, res) ->
  res.send "Hello #{req.params.name}"


metrics_router = express.Router()
metrics_router.use authCheck

# Metrics: get
# Get all metrics
metrics_router.get '', (req, res, next) ->
  metrics.get req.session.username, (err, data) ->
    throw next err if err
    res.status(200).json data

# Metrics: get by id
# Get a specific metric
metrics_router.get '/:id', (req, res, next) ->
  metrics.getById req.params.id, req.session.username, (err, data) ->
    throw next err if err
    res.status(200).json data

# Metrics: post by id
# Post a metric
metrics_router.post '/:id', (req, res, next) ->
  metrics.save req.params.id, req.body, req.session.username, (err) ->
    throw next err if err
    res.status(200).send 'metric saved'

# Metrics: delete by id
# Delete a metric
metrics_router.delete '/:id', (req, res, next) ->
  metrics.delete req.params.id, req.session.username, (err) ->
    throw next err if err
    res.status(200).send 'metric deleted'

app.use '/metrics.json', metrics_router


user_router = express.Router()

# User: get by username
# Get a specific user
user_router.get '/:username', authCheck, (req, res, next) ->
  user.get req.params.username, (err, user) ->
    throw next err if err
    if user == null
      res.status(404).send "user not found"
    else res.status(200).json user

# User: post
# Save a user with username, password and email
user_router.post '/', (req, res, next) ->
  { username, password, email} = req.body.user
  user.save username, password, email, (err) ->
    throw next err if err
    res.status(200).send "user saved"

# User: delete
# Delete a user by username
user_router.delete '/', authCheck, (req, res, next) ->
  user.remove req.session.username, (err) ->
    throw next err if err
    res.status(200).send 'user deleted'

app.use '/user', user_router

### START SERVER ###
server.listen app.get('port'), () ->
  console.log "server listening on #{app.get 'port'}"

### MIDDLEWARES DECLARATIONS ###
app.use logging_middleware
app.use error_middleware