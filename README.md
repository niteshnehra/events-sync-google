# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version:
=> 3.1.0

* How to run the test suite

=> rspec


* Deployment instructions

Create a .env in your root directory with your client-id and client-secret with below format:

GOOGLE_CLIENT_ID=google-client-id
GOOGLE_CLIENT_SECRET='google-client-secret'
GOOGLE_REDIRECT_URI=http://localhost:3000/oauth2callback
GOOGLE_AUTH_URL=https://accounts.google.com/o/oauth2/v2/auth
GOOGLE_TOKEN_URL=https://oauth2.googleapis.com/token
