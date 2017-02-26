Poema.Register(Poema.AdminCharts = {});

Poema.AdminCharts.Name = "AdminCharts";
Poema.AdminCharts.Init = function() {  return ($('#divAdminCharts').length > 0); };
Poema.AdminCharts.Exec = function() {
  google.setOnLoadCallback(Poema.AdminCharts.LibLoaded);
};

Poema.AdminCharts.LibLoaded = function() {
  $('.chart_check_box').each(function() {
    $(this).bind('change', function() {
      Poema.AdminCharts.GetData(Poema.AdminCharts.CollectParams());
    });
  });
  $('#charts-days').bind('keyup', function() {
    Poema.AdminCharts.GetData(Poema.AdminCharts.CollectParams());
  });

  Poema.AdminCharts.GetData(Poema.AdminCharts.CollectParams());
};

Poema.AdminCharts.CollectParams = function() {
  var handles = [];
  $(".chart_check_box").each(function() {
    if ($(this).is(':checked')) {
      handles.push($(this).attr('name'));
    }
  });

  return {
    handles: handles,
    days:    $('#charts-days').val(),
    type:    $("input[name='chart-type']:checked").val()
  }
};

Poema.AdminCharts.Chart = null;
Poema.AdminCharts.GetData = function(params) {
  $.ajax({
    url: Poema.Options.Get('ChartsBackendPath'),
    data: {
      'handles': params.handles,
      'days': params.days
    },
    dataType: "json",
    success: function(data) {
      if (data.total > 0) {
        var chart_values = data.results.values;
        var chart_options = {
          height:   400,
          chartArea:{left: 50, top: 40, width:"90%", height:"75%"},
          legend:   {position: 'none'},
          fontSize: 12,
          backgroundColor: "#fdfcf7"
        };
        Poema.AdminCharts.Chart = new google.visualization.LineChart(document.getElementById('json-chart'));
        Poema.AdminCharts.Chart.draw(google.visualization.arrayToDataTable(chart_values), chart_options);
      }
      else {
        if (Poema.AdminCharts.Chart) {
          Poema.AdminCharts.Chart.clearChart();
        }
      }
    }
  });
};