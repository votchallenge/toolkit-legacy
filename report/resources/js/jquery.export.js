LaTeX = new Object();

LaTeX.classes = {
    'first' : '',
    'second' : '',
    'third' : '',
    'bad' : '',
    'average' : '',
    'good' : '',
}

LaTeX.augment = function(text, classes) {

    for (var cl in classes) {
        text = '\\' + classes[cl] + '{' + text + '}';

    }

    return text;
} 

LaTeX.escape = function(s) {

	return s.replace("\\", "\\textbackslash").replace("~", "\\textasciitilde").replace("&", "\\&").replace("_", "\\_");

}

$(function () {

    function download(filename, text) {
        var element = document.createElement('a');
        element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(text));
        element.setAttribute('download', filename);
        element.style.display = 'none';
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);
    }

    function tableToLaTeX(table) {

        var tableColumns = 0;

        var tableData = [];

        $.each($(table).find('tr'), function(i, row) {

            var columns = 0;

            var rowData = [];

            $.each($(row).children(), function(i, cell) {
                cell = $(cell);
                var colspan = parseInt(cell.attr('colspan'));
                var rowspan = parseInt(cell.attr('rowspan'));
                if (!colspan) colspan = 1;
                if (!rowspan) rowspan = 1;

                var classes = cell.attr('class');
                if (classes) classes = classes.split(' '); else classes = [];

                rowData.push({'header' : cell.is('th'), 'text' : cell.text(), 'rows' : rowspan, 'columns': colspan, 'classes': classes});
                columns += colspan;

            });

            tableData.push(rowData);

            tableColumns = Math.max(columns, tableColumns);
        });

        text = '\\begin{tabular}{|' + Array(tableColumns + 1).join("c|") + '}\n';

        text += '\\hline\n';

        $.each(tableData, function(i, rowData) {

            var renderedRow = [];

            $.each(rowData, function(i, cell) {

                var rendered = LaTeX.augment(LaTeX.escape(cell.text), cell.classes);

                if (cell.header) {
                    rendered = '\\textbf{' + rendered + '}';
                }

                if (cell.rows > 1) {
                    rendered = '\\multirow{' + cell.rows + '}{*}{' + rendered + '}';
                }

                if (cell.columns > 1) {
                    rendered = '\\multicolumn{' + cell.columns + '}{ c }{' + rendered + '}';
                }

                renderedRow.push(rendered);

            });

            text += renderedRow.join(' & ') + ' \\\\\\hline\n';

        });


        text += '\\end{tabular}\n';

        return text;
    }

    function tableToCSV(table) {

        var tableColumns = 0;

        var tableData = [];

        $.each($(table).find('tr'), function(i, row) {

            var columns = 0;

            var rowData = [];

            $.each($(row).children(), function(i, cell) {
                cell = $(cell);
                var colspan = parseInt(cell.attr('colspan'));
                var rowspan = parseInt(cell.attr('rowspan'));
                if (!colspan) colspan = 1;
                if (!rowspan) rowspan = 1;

                var classes = cell.attr('class');
                if (classes) classes = classes.split(' '); else classes = [];

                rowData.push({'header' : cell.is('th'), 'text' : cell.text(), 'rows' : rowspan, 'columns': colspan, 'classes': classes});
                columns += colspan;

            });

            tableData.push(rowData);

            tableColumns = Math.max(columns, tableColumns);
        });

        text = '';

        $.each(tableData, function(i, rowData) {

            var renderedRow = [];

            $.each(rowData, function(i, cell) {

                var rendered = cell.text;

                if (cell.rows > 1) {
                    rendered = '\\multirow{' + cell.rows + '}{*}{' + rendered + '}';
                }

                if (cell.columns > 1) {
                    rendered = '\\multicolumn{' + cell.columns + '}{ c }{' + rendered + '}';
                }

                renderedRow.push(rendered);

            });

            text += renderedRow.join(' & ') + '\n';

        });

        return text;
    }

    $.each($('.table-wrapper'), function (i, table) {
        
        var toolbar = $('<div>').addClass('toolbar').prependTo(table);

        var table = $(table).find('table')[0];

        $('<a>').addClass('export-latex btn btn-default').text('LaTeX').click(function() {
                var data = tableToLaTeX(table);
                download('table.tex', data);
            }).appendTo(toolbar);

        /*$('<a>').addClass('export-csv btn btn-default').text('CSV').click(function() {
            var data = tableToCSV(table);
            }).appendTo(toolbar);*/
    });

    $('.image-wrapper img').each(function(i, image) {
        image = $(image);
        
        var eps = image.data('alternative-eps');
        var fig = image.data('alternative-fig');

        if (eps || fig) {
            var toolbar = $('<div>').addClass('toolbar').appendTo(image.parent());
            if (eps) $('<a>').addClass('export-latex btn btn-default').text('EPS').attr('href', eps).appendTo(toolbar);
            if (fig) $('<a>').addClass('export-latex btn btn-default').text('FIG').attr('href', fig).appendTo(toolbar);
        }

    });


});
