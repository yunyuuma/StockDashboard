package com.example.stockapp.service;

import lombok.RequiredArgsConstructor;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class OtpMailService {

    private final JavaMailSender mailSender;

    public void sendOtpCode(String to, String userName, String code) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(to);
        message.setSubject("【Stock App】2段階認証コード");

        message.setText(
                userName + " 様\n\n"
                        + "ログイン用の2段階認証コードは以下です。\n\n"
                        + code + "\n\n"
                        + "このコードの有効期限は5分です。\n"
                        + "心当たりがない場合は、このメールを破棄してください。\n\n"
                        + "Stock App"
        );

        mailSender.send(message);
    }
}