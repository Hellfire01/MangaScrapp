# This file contains all the instructions that alter the manga database
# add / update / download / delete / clear / todo

module MangaScrap_API
  # adds all the mangas to the database
  # mangas = array of Manga_Data where status = true && in_db = false
  # generate_html = bool indicating if Y/N must generate the html of the mangas
  def self.add(mangas, generate_html = false)
    puts 'adding ' + mangas.size.to_s + ' element(s) to database'
    html = HTML.new
    mangas.each do |manga|
      dw = manga.get_download_class
      if dw == nil
        next
      end
      if generate_html
        html_manga = HTML_manga.new(manga)
        html_manga.generate_chapter_index
      end
    end
    html.generate_index if generate_html
    puts 'done'
  end

  # updates all mangas
  # mangas = array of Manga_Data where status = true && in_db = true
  # todo_only = bool, if true, only the _todo pages / chapters are downloaded
  # fast_update = bool, if true, the update function will ignore all mangas with the 'Completed' status
  def self.update(mangas, todo_only = false, fast_update = false)
    html = HTML.new
    params = Params.instance.misc
    if fast_update
      mangas = mangas.reject{|manga| manga.data[8] == 'Completed'}
    end
    puts 'updating ' + mangas.size.to_s + ' element(s)'
    mangas.each do |manga|
      dw = manga.get_download_class(false)
      if dw == nil
        next
      end
      generate_html = (todo_only ? dw.todo : dw.update)
      if params[:delete_diff]
        if Delete_diff::delete_diff(dw.links, manga) || generate_html
          html_manga = HTML_manga.new(manga)
          html_manga.generate_chapter_index
        end
      end
    end
    html.generate_index
    html.generate_updated
    puts 'done'
  end

  # adds and then updates all mangas
  # mangas = array of Manga_Data where status = true && in_db = false
  def self.download(mangas)
    add(mangas)
    puts ''
    filter = Manga_data_filter.new(mangas)
    mangas_prepared = filter.run(false, true)
    update(mangas_prepared)
  end

  # this is the instruction to allow a re-download of a page, chapter or volume
  # it takes the arguments as given in the console, parses them an re-downloads the required elements
  def self.re_download(args, instruction_class)
    page = nil
    chapter = nil
    volume = -1
    parser = instruction_class.get_data_parser('redl')
    parser.on('p', 1) do |_page|
      page = _page[0].to_i
    end
    parser.on('c', 1) do |_chapter|
      chapter = _chapter[0].to_i
    end
    parser.on('v', 1) do |_volume|
      # todo => if site = mangafox
      volume = Utils_website_specific::Mangafox::volume_string_to_int(_volume[0])
    end
    parser.parse args
    data_to_prepare = instruction_class.data_to_prepare
    unless Re_download_module::check_redl_options(volume, chapter, page)
      instruction_class.clear_data
      puts 'cannot execute redl instruction, ignoring it'.yellow
      return
    end
    filter = Manga_data_filter.new(data_to_prepare)
    elements = filter.run(false, true)
    instruction_class.clear_data
    elements.each do |e|
      if Re_download_module::redl_manager(e, volume, chapter, page)
        html_manga = HTML_manga.new(e)
        html_manga.generate_chapter_index
      else
        return
      end
    end
  end

  # downloads the cover and description of every element and re-generates the html
  # mangas = array of Manga_Data where status = true && in_db = true
  def self.data(mangas)
    puts 'downloading data of ' + mangas.size.to_s + ' element(s)'
    html = HTML.new
    mangas.each do |manga|
      dw = manga.get_download_class
      if dw == nil
        next
      end
      dw.data
      html_manga = HTML_manga.new(manga)
      html_manga.generate_chapter_index
    end
    html.generate_index
    puts 'done'
  end

  # delete all _todo elements from the manga list
  # mangas = array of Manga_Data where status = true && in_db = true
  def self.clear(mangas)
    if Utils_user_input::require_confirmation('you are about to ' + 'delete'.red + ' all todo elements of the following element(s) :', mangas)
      db = Manga_database.instance
      mangas.each do |manga|
        db.clear_todo(manga)
      end
      puts 'deleted all todo elements'
    else
      puts 'did not delete anything'
    end
  end

  # deletes all the mangas of the list from the database
  # mangas = array of Manga_Data where status = true && in_db = true
  # delete_files = bool, if true, the files of the manga will also be deleted
  def self.delete(manga_list, delete_files = true)
    if Utils_user_input::require_confirmation('you are about to ' + 'delete'.red + ' the following element(s) from the database' + ((delete_files) ?
      ' and '.yellow + 'all of the downloaded pages' :
      ' but ' + 'not'.yellow + ' the downloaded files' ), manga_list)
      db = Manga_database.instance
      path = Params.instance.download[:manga_path]
      manga_list.each do |manga|
        db.delete_manga(manga)
        if delete_files
          site_dir = Manga_data::get_dir_from_site(manga.site)
          Utils_file::delete_files(path + site_dir + 'html/' + manga.name, '.html')
          Utils_file::delete_files(path + site_dir + 'mangas/' + manga.name, '.jpg')
        end
      end
      puts 'deleted all elements'
      HTML.new.generate_index
    else
      puts 'did not delete anything'
    end
  end
end
