/* v0.0.1 */


$(document).ready(function(){
  

// Add a in-page class to all the .display-questions
$('.block').addClass('not-in-page');

var counter = 1;
while(true) {
  // Add page counter div
  $('#pages').append('<div class="page" id="page_'+counter+'"><div class="page-number">Page '+counter+'</div></div>');
  // Start adding questions to this div
  $('.not-in-page').each(function(index) {
      // Check page div height
      if ($('#page_'+counter).height() < maxheight) {
        // Move next question onto this page
        $(this).detach().appendTo('#page_'+counter);
        
        // Check height again
        if ($('#page_'+counter).height() > maxheight) {
          // If the page is too long, remove the question
          $(this).detach().prependTo('#wrapper');
          return false;
        }
        else {
          // Remove not-in-page class so we don't process it again.
          $(this).removeClass('not-in-page');          
        }
      }
    });
  counter++;
  if($('#wrapper .not-in-page').length == 0) {
    break;
  }
}  

});