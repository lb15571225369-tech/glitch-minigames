// -- Glitch Notiforcations System
// -- Copyright (C) 2024 Glitch
// -- 
// -- This program is free software: you can redistribute it and/or modify
// -- it under the terms of the GNU General Public License as published by
// -- the Free Software Foundation, either version 3 of the License, or
// -- (at your option) any later version.
// -- 
// -- This program is distributed in the hope that it will be useful,
// -- but WITHOUT ANY WARRANTY; without even the implied warranty of
// -- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// -- GNU General Public License for more details.
// -- 
// -- You should have received a copy of the GNU General Public License
// -- along with this program. If not, see <https://www.gnu.org/licenses/>.

$(function() {
    var notificationTitles = {};
    
    window.addEventListener('message', function(event) {
        var data = event.data;
        
        if (data.type === 'showNotification') {
            var notification = $('.notification-wrapper[data-id="' + data.id + '"]');
            if (notification.length === 0) {
                notification = $('<div class="notification-wrapper"></div>');
                notification.attr('data-id', data.id);
                $('#notification-container').append(notification);
                notification.css('display', 'block');
                
                if (!data.noAnimation) {
                    setTimeout(function() { notification.addClass('show'); }, 10);
                } else {
                    notification.addClass('show');
                }
            }
            
            // checks to see if title is the same and if so, it will not add a new title group
            var titleGroup = null;
            notification.find('.notification-title-group').each(function() {
                var existingTitle = $(this).find('.notification-title').text();
                if (existingTitle === data.title) {
                    titleGroup = $(this);
                    return false
                }
            });
            
            // if no matching title found, create a new title group
            if (!titleGroup) {
                titleGroup = $('<div class="notification-title-group"></div>');
                
                var title = $('<div class="notification-title"></div>').text(data.title);
                var divider = $('<div class="notification-divider"></div>');
                
                if (data.color) {
                    title.css('color', data.color);
                    title.css('text-shadow', `0 0 10px ${data.color}CC, 0 0 20px ${data.color}88`);
                    divider.addClass('custom-color');
                    divider.attr('style', '--custom-color: ' + data.color);
                }
                
                titleGroup.append(title, divider);
                notification.append(titleGroup);
            }
            
            // always add the message body
            var body = $('<div class="notification-body" data-box-id="' + data.boxId + '"></div>').text(data.message);
            
            if (!data.noAnimation) {
                body.addClass('animate-in');
                setTimeout(function() { body.removeClass('animate-in'); }, 500);
            }
            
            titleGroup.append(body);
        }
        else if (data.type === 'addBoxToNotification') {
            var notification = $('.notification-wrapper[data-id="' + data.id + '"]');
            if (notification.length > 0) {
                var titleGroup = null;
                notification.find('.notification-title-group').each(function() {
                    var existingTitle = $(this).find('.notification-title').text();
                    if (existingTitle === data.title) {
                        titleGroup = $(this);
                        return false;
                    }
                });
                
                if (!titleGroup) {
                    titleGroup = $('<div class="notification-title-group"></div>');
                    
                    var title = $('<div class="notification-title"></div>').text(data.title);
                    var divider = $('<div class="notification-divider"></div>');
                    
                    if (data.color) {
                        title.css('color', data.color);
                        title.css('text-shadow', `0 0 10px ${data.color}CC, 0 0 20px ${data.color}88`);
                        divider.addClass('custom-color');
                        divider.attr('style', '--custom-color: ' + data.color);
                    }
                    
                    titleGroup.append(title, divider);
                    notification.append(titleGroup);
                }
                
                var body = $('<div class="notification-body" data-box-id="' + data.boxId + '"></div>').text(data.message);
                
                if (!data.noAnimation) {
                    body.addClass('animate-in');
                    setTimeout(function() { body.removeClass('animate-in'); }, 500);
                }
                
                titleGroup.append(body);
            }
        }
        else if (data.type === 'removeBoxFromNotification') {
            var body = $('.notification-wrapper[data-id="' + data.id + '"] .notification-body[data-box-id="' + data.boxId + '"]');
            if (body.length > 0) {
                body.addClass('animate-out');
                setTimeout(function() {
                    var titleGroup = body.closest('.notification-title-group');
                    body.remove();
                    
                    if (titleGroup.find('.notification-body').length === 0) {
                        titleGroup.remove();
                    }
                    
                    var notification = titleGroup.closest('.notification-wrapper');
                    if (notification.find('.notification-title-group').length === 0) {
                        notification.removeClass('show');
                        setTimeout(function() { notification.remove(); }, 300);
                    }
                }, 300);
            }
        }
        else if (data.type === 'updateBoxContent') {
            var body = $('.notification-wrapper[data-id="' + data.id + '"] .notification-body[data-box-id="' + data.boxId + '"]');
            if (body.length > 0) {
                if (data.message) {
                    body.text(data.message);
                }
                
                if (data.title) {
                    var currentGroup = body.closest('.notification-title-group');
                    var currentTitle = currentGroup.find('.notification-title').text();
                    
                    if (currentTitle !== data.title) {
                        var notification = currentGroup.closest('.notification-wrapper');
                        var targetGroup = null;
                        
                        notification.find('.notification-title-group').each(function() {
                            var groupTitle = $(this).find('.notification-title').text();
                            if (groupTitle === data.title) {
                                targetGroup = $(this);
                                return false;
                            }
                        });
                        
                        if (!targetGroup) {
                            targetGroup = $('<div class="notification-title-group"></div>');
                            
                            var title = $('<div class="notification-title"></div>').text(data.title);
                            var divider = $('<div class="notification-divider"></div>');
                            
                            if (data.color) {
                                title.css('color', data.color);
                                title.css('text-shadow', `0 0 10px ${data.color}CC, 0 0 20px ${data.color}88`);
                                divider.addClass('custom-color');
                                divider.attr('style', '--custom-color: ' + data.color);
                            }
                            
                            targetGroup.append(title, divider);
                            notification.append(targetGroup);
                        }
                        
                        body.detach().appendTo(targetGroup);
                        
                        if (currentGroup.find('.notification-body').length === 0) {
                            currentGroup.remove();
                        }
                    }
                }
            }
        }
        else if (data.type === 'removeNotification') {
            var notification = $('.notification-wrapper[data-id="' + data.id + '"]');
            if (notification.length > 0) {
                notification.removeClass('show');
                setTimeout(function() { notification.remove(); }, 300);
            }
        }
    });
});