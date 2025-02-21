module Paginatable
  extend ActiveSupport::Concern

  def paginate(collection)
    {
      data: collection,
      meta: {
        current_page: collection.current_page,
        total_pages: collection.total_pages,
        total_count: collection.total_count
      }
    }
  end
end
