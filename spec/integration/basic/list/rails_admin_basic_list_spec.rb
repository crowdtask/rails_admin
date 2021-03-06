# coding: utf-8

require 'spec_helper'

describe 'RailsAdmin Basic List', type: :request do
  subject { page }

  describe 'GET /admin' do
    it 'responds successfully' do
      visit dashboard_path
    end
  end

  describe 'GET /admin/typo' do
    it "redirects to dashboard and inform the user the model wasn't found" do
      visit '/admin/whatever'
      expect(page.driver.status_code).to eq(404)
      expect(find('.alert-danger')).to have_content("Model 'Whatever' could not be found")
    end
  end

  describe 'GET /admin/balls/545-typo' do
    it "redirects to balls index and inform the user the id wasn't found" do
      visit '/admin/ball/545-typo'
      expect(page.driver.status_code).to eq(404)
      expect(find('.alert-danger')).to have_content("Ball with id '545-typo' could not be found")
    end
  end

  describe 'GET /admin/player as list' do
    it "shows \"List of Models\", should show filters and should show column headers" do
      RailsAdmin.config.default_items_per_page = 1
      2.times { FactoryGirl.create :player } # two pages of players
      visit index_path(model_name: 'player')
      is_expected.to have_content('List of Players')
      is_expected.to have_content('Created at')
      is_expected.to have_content('Updated at')

      # it "shows the show, edit and delete links" do
      is_expected.to have_selector("li[title='Show'] a")
      is_expected.to have_selector("li[title='Edit'] a")
      is_expected.to have_selector("li[title='Delete'] a")

      # it "has the search box with some prompt text" do
      is_expected.to have_selector("input[placeholder='Filter']")

      # https://github.com/sferik/rails_admin/issues/362
      # test that no link uses the "wildcard route" with the main
      # controller and list method
      # it "does not use the 'wildcard route'" do
      is_expected.to have_selector("a[href*='all=true']") # make sure we're fully testing pagination
      is_expected.to have_no_selector("a[href^='/rails_admin/main/list']")
    end
  end

  describe 'GET /admin/player' do
    before do
      @teams = Array.new(2) do
        FactoryGirl.create(:team)
      end
      @players = [
        FactoryGirl.create(:player, retired: true, injured: true, team: @teams[0]),
        FactoryGirl.create(:player, retired: true, injured: false, team: @teams[0]),
        FactoryGirl.create(:player, retired: false, injured: true, team: @teams[1]),
        FactoryGirl.create(:player, retired: false, injured: false, team: @teams[1]),
      ]
      @comment = FactoryGirl.create(:comment, commentable: @players[2])
    end

    it 'allows to query on any attribute' do
      RailsAdmin.config Player do
        list do
          field :name
          field :team
          field :injured
          field :retired
        end
      end

      visit index_path(model_name: 'player', query: @players[0].name)
      is_expected.to have_content(@players[0].name)
      (1..3).each do |i|
        is_expected.to have_no_content(@players[i].name)
      end
    end

    it 'allows to filter on one attribute' do
      RailsAdmin.config Player do
        list do
          field :name
          field :team
          field :injured
          field :retired
        end
      end

      visit index_path(model_name: 'player', f: {injured: {'1' => {v: 'true'}}})
      is_expected.to have_content(@players[0].name)
      is_expected.to have_no_content(@players[1].name)
      is_expected.to have_content(@players[2].name)
      is_expected.to have_no_content(@players[3].name)
    end

    it 'allows to combine filters on two different attributes' do
      RailsAdmin.config Player do
        list do
          field :name
          field :team
          field :injured
          field :retired
        end
      end

      visit index_path(model_name: 'player', f: {retired: {'1' => {v: 'true'}}, injured: {'1' => {v: 'true'}}})
      is_expected.to have_content(@players[0].name)
      (1..3).each do |i|
        is_expected.to have_no_content(@players[i].name)
      end
    end

    it 'allows to filter on belongs_to relationships' do
      RailsAdmin.config Player do
        list do
          field :name
          field :team
          field :injured
          field :retired
        end
      end

      visit index_path(model_name: 'player', f: {team: {'1' => {v: @teams[0].name}}})
      is_expected.to have_content(@players[0].name)
      is_expected.to have_content(@players[1].name)
      is_expected.to have_no_content(@players[2].name)
      is_expected.to have_no_content(@players[3].name)
    end

    it 'allows to disable search on attributes' do
      RailsAdmin.config Player do
        list do
          field :position
          field :name do
            searchable false
          end
        end
      end
      visit index_path(model_name: 'player', query: @players[0].name)
      is_expected.to have_no_content(@players[0].name)
    end

    it 'allows to search a belongs_to attribute over the base table' do
      RailsAdmin.config Player do
        list do
          field PK_COLUMN
          field :name
          field :team do
            searchable Player => :team_id
          end
        end
      end
      visit index_path(model_name: 'player', f: {team: {'1' => {v: @teams.first.id}}})
      is_expected.to have_content(@players[0].name)
      is_expected.to have_content(@players[1].name)
      is_expected.to have_no_content(@players[2].name)
      is_expected.to have_no_content(@players[3].name)
    end

    it 'allows to search a belongs_to attribute over the target table' do
      RailsAdmin.config Player do
        list do
          field PK_COLUMN
          field :name
          field :team do
            searchable Team => :name
          end
        end
      end
      visit index_path(model_name: 'player', f: {team: {'1' => {v: @teams.first.name}}})
      is_expected.to have_content(@players[0].name)
      is_expected.to have_content(@players[1].name)
      is_expected.to have_no_content(@players[2].name)
      is_expected.to have_no_content(@players[3].name)
    end

    it 'allows to search a belongs_to attribute over the target table with a table name specified as a hash' do
      RailsAdmin.config Player do
        list do
          field PK_COLUMN
          field :name
          field :team do
            searchable teams: :name
          end
        end
      end
      visit index_path(model_name: 'player', f: {team: {'1' => {v: @teams.first.name}}})
      is_expected.to have_content(@players[0].name)
      is_expected.to have_content(@players[1].name)
      is_expected.to have_no_content(@players[2].name)
      is_expected.to have_no_content(@players[3].name)
    end

    it 'allows to search a belongs_to attribute over the target table with a table name specified as a string' do
      RailsAdmin.config Player do
        list do
          field PK_COLUMN
          field :name
          field :team do
            searchable 'teams.name'
          end
        end
      end
      visit index_path(model_name: 'player', f: {team: {'1' => {v: @teams.first.name}}})
      is_expected.to have_content(@players[0].name)
      is_expected.to have_content(@players[1].name)
      is_expected.to have_no_content(@players[2].name)
      is_expected.to have_no_content(@players[3].name)
    end

    it 'allows to search a belongs_to attribute over the label method by default' do
      RailsAdmin.config Player do
        list do
          field PK_COLUMN
          field :name
          field :team
        end
      end
      visit index_path(model_name: 'player', f: {team: {'1' => {v: @teams.first.name}}})
      is_expected.to have_content(@players[0].name)
      is_expected.to have_content(@players[1].name)
      is_expected.to have_no_content(@players[2].name)
      is_expected.to have_no_content(@players[3].name)
    end

    it 'allows to search a belongs_to attribute over the target table when an attribute is specified' do
      RailsAdmin.config Player do
        list do
          field PK_COLUMN
          field :name
          field :team do
            searchable :name
          end
        end
      end
      visit index_path(model_name: 'player', f: {team: {'1' => {v: @teams.first.name}}})
      is_expected.to have_content(@players[0].name)
      is_expected.to have_content(@players[1].name)
      is_expected.to have_no_content(@players[2].name)
      is_expected.to have_no_content(@players[3].name)
    end

    it 'allows to search over more than one attribute' do
      RailsAdmin.config Player do
        list do
          field PK_COLUMN
          field :name
          field :team do
            searchable [:name, {Player => :team_id}]
          end
        end
      end
      visit index_path(model_name: 'player', f: {team: {'1' => {v: @teams.first.name}, '2' => {v: @teams.first.id, o: 'is'}}})
      is_expected.to have_content(@players[0].name)
      is_expected.to have_content(@players[1].name)
      is_expected.to have_no_content(@players[2].name)
      is_expected.to have_no_content(@players[3].name)
      # same with a different id
      visit index_path(model_name: 'player', f: {team: {'1' => {v: @teams.first.name}, '2' => {v: @teams.last.id, o: 'is'}}})
      is_expected.to have_no_content(@players[0].name)
      is_expected.to have_no_content(@players[1].name)
      is_expected.to have_no_content(@players[2].name)
      is_expected.to have_no_content(@players[3].name)
    end

    it 'allows to search a has_many attribute over the target table' do
      RailsAdmin.config Player do
        list do
          field PK_COLUMN
          field :name
          field :comments do
            searchable :content
          end
        end
      end
      visit index_path(model_name: 'player', f: {comments: {'1' => {v: @comment.content}}})
      is_expected.to have_no_content(@players[0].name)
      is_expected.to have_no_content(@players[1].name)
      is_expected.to have_content(@players[2].name)
      is_expected.to have_no_content(@players[3].name)
    end

    it 'displays base filters when no filters are present in the params' do
      RailsAdmin.config Player do
        list do
          filters [:name, :team]
        end
      end
      get index_path(model_name: 'player')

      options = {
        index: 1,
        label: 'Name',
        name: 'name',
        type: 'string',
        value: '',
        operator: nil,
      }
      expect(response.body).to include("$.filters.append(#{options.to_json});")

      options = {
        index: 2,
        select_options: '',
        label: 'Team',
        name: 'team',
        type: 'belongs_to_association',
        value: '',
        operator: nil,
      }
      expect(response.body).to include("$.filters.append(#{options.to_json});")
    end
  end

  describe 'GET /admin/player with 2 objects' do
    before do
      @players = FactoryGirl.create_list(:player, 2)
      visit index_path(model_name: 'player')
    end

    it "shows \"2 results\"" do
      is_expected.to have_content('2 players')
    end
  end

  describe 'GET /admin/player with 2 objects' do
    before do
      @players = FactoryGirl.create_list(:player, 2)
      visit index_path(model_name: 'player')
    end

    it "shows \"2 results\"" do
      is_expected.to have_content('2 players')
    end
  end

  describe 'GET /admin/player with 3 pages, page 2' do
    before do
      RailsAdmin.config.default_items_per_page = 1
      items_per_page = RailsAdmin.config.default_items_per_page
      (items_per_page * 3).times { FactoryGirl.create(:player) }
      visit index_path(model_name: 'player', page: 2)
    end

    it 'paginates correctly' do
      expect(find('ul.pagination li:first')).to have_content('« Prev')
      expect(find('ul.pagination li:last')).to have_content('Next »')
      expect(find('ul.pagination li.active')).to have_content('2')
    end
  end

  describe 'list with 3 pages, page 3' do
    before do
      items_per_page = RailsAdmin.config.default_items_per_page
      @players = Array.new((items_per_page * 3)) { FactoryGirl.create(:player) }
      visit index_path(model_name: 'player', page: 3)
    end

    it 'paginates correctly and contain the right item' do
      expect(find('ul.pagination li:first')).to have_content('« Prev')
      expect(find('ul.pagination li:last')).to have_content('Next »')
      expect(find('ul.pagination li.active')).to have_content('3')
    end
  end

  describe 'GET /admin/player show all' do
    it 'responds successfully with a single model' do
      FactoryGirl.create :player
      visit index_path(model_name: 'player', all: true)
      expect(find('div.total-count')).to have_content('1 player')
      expect(find('div.total-count')).not_to have_content('1 players')
    end

    it 'responds successfully with multiple models' do
      FactoryGirl.create_list(:player, 2)
      visit index_path(model_name: 'player', all: true)
      expect(find('div.total-count')).to have_content('2 players')
    end
  end

  describe 'GET /admin/player show with pagination disabled by :associated_collection' do
    it 'responds successfully' do
      @team = FactoryGirl.create :team
      Array.new(2) { FactoryGirl.create :player, team: @team }
      visit index_path(model_name: 'player', associated_collection: 'players', compact: true, current_action: 'update', source_abstract_model: 'team', source_object_id: @team.id)
      expect(find('div.total-count')).to have_content('2 players')
    end
  end

  describe 'list as compact json' do
    it 'has_content an array with 2 elements and contain an array of elements with keys id and label' do
      FactoryGirl.create_list(:player, 2)
      get index_path(model_name: 'player', compact: true, format: :json)
      expect(ActiveSupport::JSON.decode(response.body).length).to eq(2)
      ActiveSupport::JSON.decode(response.body).each do |object|
        expect(object).to have_key('id')
        expect(object).to have_key('label')
      end
    end
  end

  describe 'search operator' do
    let(:player) { FactoryGirl.create :player }

    before do
      expect(Player.count).to eq(0)
    end

    it 'finds the player if the query matches the default search operator' do
      RailsAdmin.config do |config|
        config.default_search_operator = 'ends_with'
        config.model Player do
          list { field :name }
        end
      end
      visit index_path(model_name: 'player', query: player.name[2, -1])
      is_expected.to have_content(player.name)
    end

    it 'does not find the player if the query does not match the default search operator' do
      RailsAdmin.config do |config|
        config.default_search_operator = 'ends_with'
        config.model Player do
          list { field :name }
        end
      end
      visit index_path(model_name: 'player', query: player.name[0, 2])
      is_expected.to have_no_content(player.name)
    end

    it 'finds the player if the query matches the specified search operator' do
      RailsAdmin.config Player do
        list do
          field :name do
            search_operator 'starts_with'
          end
        end
      end
      visit index_path(model_name: 'player', query: player.name[0, 2])
      is_expected.to have_content(player.name)
    end

    it 'does not find the player if the query does not match the specified search operator' do
      RailsAdmin.config Player do
        list do
          field :name do
            search_operator 'starts_with'
          end
        end
      end
      visit index_path(model_name: 'player', query: player.name[1..-1])
      is_expected.to have_no_content(player.name)
    end
  end

  describe 'list for objects with overridden to_param' do
    before do
      @ball = FactoryGirl.create :ball

      visit index_path(model_name: 'ball')
    end

    it 'shows the show, edit and delete links with valid url' do
      is_expected.to have_selector("td a[href$='/admin/ball/#{@ball.id}']")
      is_expected.to have_selector("td a[href$='/admin/ball/#{@ball.id}/edit']")
      is_expected.to have_selector("td a[href$='/admin/ball/#{@ball.id}/delete']")
    end
  end

  describe 'Scopes' do
    before do
      RailsAdmin.config do |config|
        config.model Team do
          list do
            scopes [nil, :red, :white]
          end
        end
      end
      @teams = [
        FactoryGirl.create(:team, color: 'red'),
        FactoryGirl.create(:team, color: 'red'),
        FactoryGirl.create(:team, color: 'white'),
        FactoryGirl.create(:team, color: 'black'),
      ]
    end

    it 'displays configured scopes' do
      visit index_path(model_name: 'team')
      expect(find('#scope_selector li:first')).to have_content('All')
      expect(find('#scope_selector li:nth-child(2)')).to have_content('Red')
      expect(find('#scope_selector li:nth-child(3)')).to have_content('White')
      expect(find('#scope_selector li:last')).to have_content('White')
      expect(find('#scope_selector li.active')).to have_content('All')
    end

    it 'shows only scoped records' do
      visit index_path(model_name: 'team')
      is_expected.to have_content(@teams[0].name)
      is_expected.to have_content(@teams[1].name)
      is_expected.to have_content(@teams[2].name)
      is_expected.to have_content(@teams[3].name)

      visit index_path(model_name: 'team', scope: 'red')
      expect(find('#scope_selector li.active')).to have_content('Red')
      is_expected.to have_content(@teams[0].name)
      is_expected.to have_content(@teams[1].name)
      is_expected.to have_no_content(@teams[2].name)
      is_expected.to have_no_content(@teams[3].name)

      visit index_path(model_name: 'team', scope: 'white')
      expect(find('#scope_selector li.active')).to have_content('White')
      is_expected.to have_no_content(@teams[0].name)
      is_expected.to have_no_content(@teams[1].name)
      is_expected.to have_content(@teams[2].name)
      is_expected.to have_no_content(@teams[3].name)
    end
    it 'shows all records instead when scope not in list' do
      visit index_path(model_name: 'team', scope: 'green')
      is_expected.to have_content(@teams[0].name)
      is_expected.to have_content(@teams[1].name)
      is_expected.to have_content(@teams[2].name)
      is_expected.to have_content(@teams[3].name)
    end
    describe 'i18n' do
      before :each do
        en = {admin: {scopes: {
          _all: 'every',
          red: 'krasnyj',
        }}}
        I18n.backend.store_translations(:en, en)
      end
      after { I18n.reload! }
      context 'global' do
        it 'displays configured scopes' do
          visit index_path(model_name: 'team')
          expect(find('#scope_selector li:first')).to have_content('every')
          expect(find('#scope_selector li:nth-child(2)')).to have_content('krasnyj')
          expect(find('#scope_selector li:nth-child(3)')).to have_content('White')
          expect(find('#scope_selector li:last')).to have_content('White')
          expect(find('#scope_selector li.active')).to have_content('every')
        end
      end
      context 'per model' do
        before :each do
          en = {admin: {scopes: {team: {
            _all: 'any',
            red: 'kr',
          }}}}
          I18n.backend.store_translations(:en, en)
        end
        after { I18n.reload! }
        it 'displays configured scopes' do
          visit index_path(model_name: 'team')
          expect(find('#scope_selector li:first')).to have_content('any')
          expect(find('#scope_selector li:nth-child(2)')).to have_content('kr')
          expect(find('#scope_selector li:nth-child(3)')).to have_content('White')
          expect(find('#scope_selector li:last')).to have_content('White')
          expect(find('#scope_selector li.active')).to have_content('any')
        end
      end
    end
  end

  describe 'Row CSS class' do
    before do
      RailsAdmin.config do |config|
        config.model Team do
          list do
            row_css_class { 'my_class' }
          end
        end
      end
      @teams = [
        FactoryGirl.create(:team, color: 'red'),
        FactoryGirl.create(:team, color: 'red'),
        FactoryGirl.create(:team, color: 'white'),
        FactoryGirl.create(:team, color: 'black'),
      ]
    end
  end

  describe 'list filter for belongs to  association', js: true do
    let!(:teams) do
      [
        FactoryGirl.create(:team, name: 'Red Devils', color: 'red'),
        FactoryGirl.create(:team, name: 'Red Rockets', color: 'red'),
        FactoryGirl.create(:team, name: 'White Walters', color: 'white'),
        FactoryGirl.create(:team, name: 'Black Magics', color: 'black'),
      ]
    end

    let!(:players) do
      [
        FactoryGirl.create(:player, name: 'Harry Hipster', team: teams.first),
        FactoryGirl.create(:player, name: 'Micky Mighty', team: teams[1]),
        FactoryGirl.create(:player, name: 'Colby James', team: teams[2]),
        FactoryGirl.create(:player, name: 'Johnny Jangle', team: teams.last),
      ]
    end

    describe 'filter by string' do
      before do
        RailsAdmin.config do |config|
          config.model Player do
            field :name
            field :team, :belongs_to_association do
              searchable [:name]
              filterable true
            end

            list do
              filters [:team]
            end
          end
        end
      end

      it 'allows user to enter text to search associated field' do
        visit index_path(model_name: 'player')

        teams.each do |team|
          is_expected.to have_selector(list_item_with_title(team.name))
        end

        within('span#filters_box') do
          find(text_filter_selector('team')).set('Red')
        end
        click_button('Refresh')

        teams.select { |t| t.name =~ /Red/ }.each do |team|
          is_expected.to have_selector(list_item_with_title(team.name))
        end

        teams.reject { |t| t.name =~ /Red/ }.each do |team|
          is_expected.to_not have_selector(list_item_with_title(team.name))
        end
      end
    end

    describe 'filter by collection' do
      before do
        RailsAdmin.config do |config|
          config.model Player do
            field :name
            field :team, :belongs_to_association do
              searchable [:id]
              filterable true

              filter_by do
                Team.all.map { |t| [t.name, t.id] }
              end
            end

            list do
              filters [:team]
            end
          end
        end
      end

      it 'allows user to choose from select list to search associated field' do
        visit index_path(model_name: 'player')
        teams.each do |team|
          is_expected.to have_selector(list_item_with_title(team.name))
        end

        within('span#filters_box') do
          team_select = find(select_filter_selector('team'))
          team_select.select('Red Devils')
        end
        unfiltered_url =  page.current_url

        click_button('Refresh')

        expect(unfiltered_url).to_not eq page.current_url

        teams.select { |t| t.name =~ /Red Devils/ }.each do |team|
          is_expected.to have_selector(list_item_with_title(team.name))
        end

        teams.reject { |t| t.name =~ /Red Devils/ }.each do |team|
          is_expected.to_not have_selector(list_item_with_title(team.name))
        end
      end
    end
  end

  describe 'list filter for many to many association', js: true do
    let!(:teams) do
      [
        FactoryGirl.create(:team, name: 'Red Devils', color: 'red'),
        FactoryGirl.create(:team, name: 'Red Rockets', color: 'red'),
        FactoryGirl.create(:team, name: 'White Walters', color: 'white'),
        FactoryGirl.create(:team, name: 'Black Magics', color: 'black'),
      ]
    end

    let!(:fans) do
      [
        FactoryGirl.create(:fan, name: 'Larry', teams: [teams.first]),
        FactoryGirl.create(:fan, name: 'Moe', teams: teams),
        FactoryGirl.create(:fan, name: 'Curly', teams: teams.slice(0, 2)),
        FactoryGirl.create(:fan, name: 'Nicola Tesla', teams: [teams.last]),
      ]
    end

    before do
      RailsAdmin.config do |config|
        config.model Team do
          field :name
          field :fans, :has_and_belongs_to_many_association do
            searchable [:id]
            filterable true

            filter_by do
              Fan.all.map { |c| [c.name, c.id] }
            end

            multi_select do
              true
            end
            check_boxes do
              true
            end
          end

          list do
            filters [:fans]
          end
        end
      end
    end

    describe 'filter_by multi_select check_boxes' do
      it 'check all associated checkboxes returns all objects' do
        visit index_path(model_name: 'team')

        within('span#filters_box') do
          fans.each do |fan|
            find(checkbox_filter_selector('fans', fan)).set(true)
          end
        end
        unfiltered_url =  page.current_url

        click_button('Refresh')

        expect(unfiltered_url).to_not eq page.current_url

        teams.each do |team|
          is_expected.to have_selector(list_item_with_title(team.name))
        end
      end

      it 'check one associated checkbox return only that objects that are associated' do
        visit index_path(model_name: 'team')

        larry = fans.detect { |fan| fan.name == 'Larry' }
        within('span#filters_box') do
          find(checkbox_filter_selector('fans', larry)).set(true)
        end
        click_button('Refresh')

        within('span#filters_box') do
          expect(find(checkbox_filter_selector('fans', larry)).checked?).to be_truthy
        end

        larry.teams.each do |team|
          is_expected.to have_selector(list_item_with_title(team.name))
        end

        (teams - larry.teams).each do |team|
          is_expected.to_not have_selector(list_item_with_title(team.name))
        end
      end
    end
  end

  describe 'filter list for one to many association', js: true do
    let!(:teams) do
      [
        FactoryGirl.create(:team, name: 'Red Devils', color: 'red'),
        FactoryGirl.create(:team, name: 'Red Rockets', color: 'red'),
        FactoryGirl.create(:team, name: 'White Walters', color: 'white'),
        FactoryGirl.create(:team, name: 'Black Magics', color: 'black'),
      ]
    end

    let!(:players) do
      [
        FactoryGirl.create(:player, name: 'Harry Hipster', team: teams.first),
        FactoryGirl.create(:player, name: 'Micky Mighty', team: teams[1]),
        FactoryGirl.create(:player, name: 'Colby James', team: teams[2]),
        FactoryGirl.create(:player, name: 'Johnny Jangle', team: teams.last),
      ]
    end

    before do
      RailsAdmin.config do |config|
        config.model Team do
          field :name
          field :players, :has_many_association do
            searchable [:id]
            filterable true

            filter_by do
              Player.all.map { |c| [c.name, c.id] }
            end

            multi_select do
              true
            end
            check_boxes do
              true
            end
          end

          list do
            filters [:players]
          end
        end
      end
    end

    describe 'filter_by multi_select check_boxes' do
      it 'check all associated checkboxes returns all objects' do
        visit index_path(model_name: 'team')

        within('span#filters_box') do
          players.each do |player|
            find(checkbox_filter_selector('players', player)).set(true)
          end
        end
        unfiltered_url =  page.current_url

        click_button('Refresh')

        expect(unfiltered_url).to_not eq page.current_url

        teams.each do |team|
          is_expected.to have_selector(list_item_with_title(team.name))
        end
      end

      it 'check one associated checkbox return only that objects that are associated' do
        visit index_path(model_name: 'team')

        harry_hipster = players.detect { |player| player.name == 'Harry Hipster' }
        within('span#filters_box') do
          find(checkbox_filter_selector('players', harry_hipster)).set(true)
        end
        click_button('Refresh')

        within('span#filters_box') do
          expect(find(checkbox_filter_selector('players', harry_hipster)).checked?).to be_truthy
        end

        is_expected.to have_selector(list_item_with_title(harry_hipster.team.name))

        (teams - [harry_hipster.team]).each do |team|
          is_expected.to_not have_selector(list_item_with_title(team.name))
        end
      end
    end
  end
end
