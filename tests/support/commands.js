// ***********************************************
// This example commands.js shows you how to
// create the custom command: 'login'.
//
// The commands.js file is a great place to
// modify existing commands and create custom
// commands for use throughout your tests.
//
// You can read more about custom commands here:
// https://on.cypress.io/api/commands
// ***********************************************
//
// Cypress.addParentCommand("login", function(email, password){
//   var email    = email || "joe@example.com"
//   var password = password || "foobar"
//
//   var log = Cypress.Log.command({
//     name: "login",
//     message: [email, password],
//     consoleProps: function(){
//       return {
//         email: email,
//         password: password
//       }
//     }
//   })
//
//   cy
//     .visit("/login", {log: false})
//     .contains("Log In", {log: false})
//     .get("#email", {log: false}).type(email, {log: false})
//     .get("#password", {log: false}).type(password, {log: false})
//     .get("button", {log: false}).click({log: false}) //this should submit the form
//     .get("h1", {log: false}).contains("Dashboard", {log: false}) //we should be on the dashboard now
//     .url({log: false}).should("match", /dashboard/, {log: false})
//     .then(function(){
//       log.snapshot().end()
//     })
// })

Cypress.addParentCommand('tweet', function(handle, content) {
  var handle = handle || 'cypressbot'
  var content = content || 'foobar'

  cy.get('#tweet_handle').clear().type(handle)
    .get('#tweet_content').clear().type(content)
    .get('input[name=commit]').click()
})

Cypress.addParentCommand('eelogin', function(username, password) {
  var username = username || 'guest'
  var password = password || 'password'

  cy.get("input[name=uid]")
    .clear()
    .type(username)
    .get("input[name=password]", {log: false})
    .clear({log: false})
    .type(password, {log: false})
    .get("button.button.button-primary:first")
    .click()
})
