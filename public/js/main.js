$(function() {
  var $webhookSecret = $('.js-webhook-secret')
  $('.js-details-target').click(function(e) {
    e.preventDefault();
    $webhookSecret.toggleClass('open');
    $webhookSecret.find('input').prop('disabled', function(i, v) { return !v; });
  });
});
