# frozen_string_literal: true

class BooksController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_correct_user, only: %i[edit update destroy]

  def show
    @book = Book.find(params[:id])
    @book_comment = BookComment.new
    impressionist(@book, nil, unique: [:ip_address])
  end

  def index
    # set the date of start
    from = (Time.current - 6.day).at_beginning_of_day
    # set the date of end
    to = Time.current.at_end_of_day
    # sort books from the date
    @books = Book.includes(:favorited_users)
                 .sort_by do |x|
      x.favorited_users.includes(:favorites).where(created_at: from...to).size
    end.reverse

    @book = Book.new
  end

  def create
    @book = Book.new(book_params)
    @book.user_id = current_user.id
    if @book.save
      redirect_to book_path(@book), notice: 'You have created book successfully.'
    else
      @books = Book.all
      render 'index'
    end
  end

  def edit; end

  def update
    if @book.update(book_params)
      redirect_to book_path(@book), notice: 'You have updated book successfully.'
    else
      render 'edit'
    end
  end

  def destroy
    @book.destroy
    redirect_to books_path
  end

  def search_by_calender
    from = Time.parse(params[:search_date]).at_beginning_of_day
    to = Time.parse(params[:search_date]).at_end_of_day
    @result = Book.where(user_id: params[:user_id], created_at: from...to).count
    render 'post_count/search'
  end

  def order_by_date
    @book = Book.new
    @books = Book.all.order(create_at: :desc)
    render 'index'
  end

  def order_by_rate
    @book = Book.new
    @books = Book.all.order(rate: :desc)
    render 'index'
  end

  def search_by_tag
    tag = ActsAsTaggableOn::Tag.all.find_by(name: params[:tag_name])
    tag_name = tag.present? ? tag.name : nil
    @books = Book.tagged_with(tag_name)
    @book = Book.new
    render 'index'
  end

  private

  def book_params
    params.require(:book).permit(:title, :body, :rate, :tag_list)
  end

  def ensure_correct_user
    @book = Book.find(params[:id])
    redirect_to books_path unless @book.user == current_user
  end
end
