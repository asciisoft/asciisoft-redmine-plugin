# frozen_string_literal: true

get  'asciisoft/notifications', to: 'asciisoft_notifications#index'
post 'asciisoft/notifications/read_all', to: 'asciisoft_notifications#read_all'
post 'asciisoft/mode', to: 'asciisoft_user_settings#update_mode'
get  'projects/:project_id/asciisoft_header/image', to: 'asciisoft_project_headers#image',
                                                    as: 'asciisoft_project_header_image'
post 'projects/:project_id/asciisoft_header', to: 'asciisoft_project_headers#update',
                                              as: 'asciisoft_project_header'
