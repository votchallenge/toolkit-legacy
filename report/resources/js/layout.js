
$(function () {

    var title = $('h1').first().text();

    $('body').prepend($('<div />').attr('id', 'header')
        .append($('<div />').addClass('navbar navbar-default navbar-fixed-top')
        .append($('<div />').addClass('container')
        .append($('<div />').addClass('navbar-header')
        .append($('<a />').addClass('navbar-brand').text(title).attr('href', '#'))))));

    var modal = Object;
    modal.wrapper = $('<div />').addClass('modal').attr('tabindex', '-1');
    modal.dialog = $('<div />').addClass('modal-dialog modal-lg').appendTo(modal.wrapper);
    modal.content = $('<div />').addClass('modal-content').appendTo(modal.dialog);
    modal.header = $('<div />').addClass('modal-header').appendTo(modal.content);
    modal.title = $('<span />').appendTo(modal.header);
    modal.header.append($('<button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>'));
    modal.body = $('<div />').addClass('modal-body').appendTo(modal.content);
    $('body').append(modal.wrapper.modal({'show': false}));

    // Format stacking elements into grid
    $('.stacking').each(function(i, candidate) {
        candidate = $(candidate);
        if (candidate.prev('.stacking').length > 0)
            return;

        var sequence = candidate;
        var current = candidate;

        for (current = candidate.next('.stacking'); current.length > 0; current = current.next('.stacking')) {
            sequence = sequence.add(current);
        }

        if (sequence.length < 2)
            return;

        var wrapper = $('<div/>').addClass("row");

        candidate.before(wrapper);

        sequence.each(function (i, element) {
            element = $(element);
            element.remove().appendTo($('<div />').addClass('col-md-4').appendTo(wrapper));
        });

    });

    $('.image-wrapper img').click(function(event) {

        modal.title.text($(this).parent().find('.title').first().text());

        modal.body.empty().append($(this).clone());

        modal.wrapper.modal('show');

    });

    // Build navigation
    var section = null;
    var anchorId = 0;

    var menu = $('<ul/>').addClass('nav navbar-nav').appendTo($('#header .container')).wrap($('<div/>').attr('id', 'navbar'));

    $('body > .container h2').each(function(i, header) {
        header = $(header);

        section = $('<li/>').append($('<a/>').attr('href', '#navigation-' + anchorId).text(header.text())).appendTo(menu);

        header.append($('<a/>').attr('name', 'navigation-' + anchorId).attr('id', 'navigation-' + anchorId).attr('href', '#'));

        anchorId++;

    });

    $('body').scrollspy({ target: '#navbar' });

});
