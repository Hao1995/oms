module Common
  class PaginationDto
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :total, :integer
    attribute :per_page, :integer
    attribute :current_page, :integer

    def total_pages
      return 0 if total.zero? || per_page.zero?
      (total / per_page).ceil
    end

    def next_page
      current_page < total_pages ? current_page + 1 : nil
    end

    def prev_page
      current_page > 1 ? current_page - 1 : nil
    end

    def first_page?
      current_page == 1
    end

    def last_page?
      current_page == total_pages
    end
  end
end
