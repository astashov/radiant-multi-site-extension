require_dependency 'application'

module MultiSite
  # We should disable multisites for test environment, because we can break some other tests
  # that don't know about sites. :) No worries, for MultiSite specs it
  # will be enable in the spec_helper file.
  @enable_multisite ||= ENV["RAILS_ENV"] == "test" ? false : true
  class << self
    attr_accessor :enable_multisite
  end
end

class MultiSiteExtension < Radiant::Extension
  version "0.3"
  description %{ Enables virtual sites to be created with associated domain names.
                 Also scopes the sitemap view to any given page (or the root of an
                 individual site). }
  url "http://radiantcms.org/"

  define_routes do |map|
    if MultiSite.enable_multisite
      map.resources :sites, :path_prefix => "/admin",
                    :member => {
                      :move_higher => :post,
                      :move_lower => :post,
                      :move_to_top => :put,
                      :move_to_bottom => :put
                    }
    end
  end

  def activate
    if MultiSite.enable_multisite
      Page.send :include, MultiSite::PageExtensions
      SiteController.send :include, MultiSite::SiteControllerExtensions
      Admin::PagesController.send :include, MultiSite::PagesControllerExtensions
      ResponseCache.send :include, MultiSite::ResponseCacheExtensions
      Radiant::Config["dev.host"] = 'preview' if Radiant::Config.table_exists?
      # Add site navigation
      admin.pages.index.add :top, "site_subnav"
      admin.tabs.add "Sites", "/admin/sites", :visibility => [:admin]
    end
  end

  def deactivate
    admin.tabs.remove "Sites"
  end

end
