class ProjectTelegramChatsController < ApplicationController
  before_action :find_project
  before_action :require_admin_or_project_manager
  before_action :find_chat, only: [:update, :destroy]

  def create
    @chat = @project.project_telegram_chats.new(chat_params)

    respond_to do |format|
      if @chat.save
        format.html do
          flash[:notice] = 'Telegram чат успешно добавлен'
          redirect_to settings_project_path(@project)
        end
        format.json { render json: { success: true, message: 'Telegram чат успешно добавлен' }, status: :ok }
      else
        format.html do
          flash[:error] = @chat.errors.full_messages.join(', ')
          redirect_to settings_project_path(@project)
        end
        format.json { render json: { success: false, errors: @chat.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @chat.update(chat_params)
        format.html do
          flash[:notice] = 'Telegram чат успешно обновлен'
          redirect_to settings_project_path(@project)
        end
        format.json { render json: { success: true, message: 'Telegram чат успешно обновлен' }, status: :ok }
      else
        format.html do
          flash[:error] = @chat.errors.full_messages.join(', ')
          redirect_to settings_project_path(@project)
        end
        format.json { render json: { success: false, errors: @chat.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @chat.destroy
    respond_to do |format|
      format.html do
        flash[:notice] = 'Telegram чат успешно удален'
        redirect_to settings_project_path(@project)
      end
      format.json { render json: { success: true, message: 'Telegram чат успешно удален' }, status: :ok }
    end
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  end

  def find_chat
    @chat = @project.project_telegram_chats.find(params[:id])
  end

  def chat_params
    params.require(:project_telegram_chat).permit(:chat_id, :enabled)
  end

  def require_admin_or_project_manager
    unless User.current.admin? || User.current.allowed_to?(:manage_project, @project)
      render_403
      return false
    end
  end
end
