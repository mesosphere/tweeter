describe('Tweeter Demo', function() {
  it('can post and read tweets', function() {
    cy.readFile('ci-conf.json')
      .then(function(settings) {
        cy.visit(settings.tweeter_url);

        var handle = 'cypressbot';
        var myTweet = 'my first tweet';

        cy.tweet(handle, myTweet)
          .get('div.list-group')    // tweet listing
          .find('p.tweet-content')  // tweet text/content
          .contains(myTweet);
      });
  });

  it('can view load balancing', function() {
    cy.readFile('ci-conf.json')
      .then(function(settings) {
        cy.visit(settings.url);

        if ('username' in settings && settings['username'] != '') {
          cy.eelogin(settings.username, settings.password)

          cy.get('.sidebar-menu-item-label').contains('Networking').click();
          cy.get('.sidebar-menu-item a').contains('Service Addresses').click();
          // find the 1.1.1.1 network and click on it
          cy.get('table tbody tr td a').contains('1.1.1').click()
          // there should be a canvas element. this is where the graph
          // is drawn. not sure what to verify within the canvas.
          cy.get('canvas').should('have.length.of.at.least', 1)
          // make sure there are at least 3 IPs in the IP table.
          cy.get('table tbody tr:visible').should('have.length', 3)
        }
      });
  });
});
