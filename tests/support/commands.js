Cypress.addParentCommand('tweet', function(handle, content) {
  var handle = handle || 'cypressbot';
  var content = content || 'foobar';

  cy.get('#tweet_handle').clear().type(handle)
    .get('#tweet_content').clear().type(content)
    .get('input[name=commit]').click();
});

Cypress.addParentCommand('eelogin', function(username, password) {
  var username = username || 'guest';
  var password = password || 'password';

  cy.clearCookies();

  cy.get("input[name=uid]")
    .clear()
    .type(username)
    .get("input[name=password]", {log: false})
    .clear({log: false})
    .type(password, {log: false})
    .get("button.button.button-primary:first")
    .click();
});
