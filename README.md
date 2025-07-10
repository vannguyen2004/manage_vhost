# manage_vhost
### Giới thiệu
Đây là chương trình quản lý virtual host trên Server cho người muốn tự động hóa việc quản trị
### Một số chức năng chính
- Tạo Virtual Host: User đã có sẵn trên hệ thống, tạo cho một user mới
- Danh sách Virtual host: In ra các thông tin cơ bản của cấu hình Virtual Host {User sở hữu, Server Name, Document root, phiên bản PHP}, xem file cấu hình của một Virtual Host
- Xóa cấu hình Virtual Host
- Chỉnh sửa cấu hình Virtual Host: Thay đổi phiên bản PHP, thay đổi Server Name, Đổi mật khẩu tài khoản database
### Một số chức năng bổ sung
- Check DNS record
- Create, Update, List, Delete DNS trên Cloudflare
- backup source database
- Setup SSL
- Set up wordpress
### Những điểm chính  
Các chức năng sẽ được tự động hóa. Tuy nhiên vẫn cần thủ công ở phần gán quyền cho user khi tạo mới.  
```
vi /etc/adduser.conf
DIR_MODE=0711
```
Lý do. Mặc định khi user được tạo được cấu hình 750. Khi source web nằm ở thư mục người dùng thì các User không thể truy cập được.
