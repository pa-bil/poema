class ForumsController < ForumsCommonController
  before_filter :load_data, :except => [:index]
  before_filter :check_access, :except => [:index]

  # Filtrowanie dostępu do akcji kontrolera
  access_control do
    allow :root
    allow all
  end

  private

  def load_data
    @forum = Forum.find(params[:id])
  end

  public

  # Lista forów
  def index
    # Nie pokazujemy na liście zbanowanych lub niewidocznych forów, nie mniej jednak pozwalamy osobom mającym uprawnienia na wejście, jeśli znają id
    @forums = Forum.list
    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @forums }
    end
  end

  def show
    # Nie pokazujemy na liście zbanowanych wątków, nie mniej jednak pozwalamy osobom mającym uprawnienia na wejście, jeśli znają id
    @forum_threads = @forum.list_threads params[:page]
    add_alert I18n.t('controller.forums.prohibited') unless @forum.can_show?

    StatCounterObject.increment_counter 'view'

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @forum_threads }
    end
  end
end
