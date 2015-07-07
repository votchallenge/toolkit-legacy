LaTeX = new Object();

LaTeX.classes = {
    'first' : '';
    'second' : '';
    'third' : '';
    'bad' : '';
    'average' : '';
    'good' : '';
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


    $.each($('.export table'), function (i, table) {

        var converted = $('<pre>').hide();

        var toggle = $('<a>').addClass('latexlink').text('As LaTeX').click(function() {

            if (converted.is(':visible')) {
                converted.hide();
                $(table).show();
                toggle.text('As LaTeX');
            } else {
                var data = tableToLaTeX(table);
                converted.text(data);
                $(table).hide();
                converted.show();
                toggle.text('As HTML');
            }
        });

        $(table).after(toggle);
        $(table).after(converted);


    });

});
