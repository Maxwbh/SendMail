/*
   Maxwell  da Silva Oliveira
   (31) 9325.7479/ 9474.8854 
   maxwbh@gmail.com
   http://br.linkedin.com/in/maxwbh
*/
CREATE OR REPLACE PROCEDURE PRD_ENVIA_EMAIL(pusuario      IN VARCHAR2,
                                               psenha        IN VARCHAR2,
                                               pde           IN VARCHAR2,
                                               ppara         IN VARCHAR2,
                                               passunto      IN VARCHAR2,
                                               body          IN VARCHAR2,
                                               p_attach_name IN VARCHAR2 DEFAULT NULL,
                                               p_attach_mime IN VARCHAR2 DEFAULT 'application/pdf', --PDF  ( Verificar mime type em http://www.iana.org/assignments/media-types ) ,
                                               p_attach_blob IN BLOB DEFAULT NULL) IS

    -- Autor    : Maxwell da Silva Oliveira
    -- Data     : 06/02/2013
    -- Objetivo : Envia e-mail com arquivo anexo


    vconexao   utl_smtp.connection; --Guarda a Conexao com o servidor
    l_boundary VARCHAR2(50) := '----=*#abc1234321cba#*=';
    l_step     PLS_INTEGER := 57;
    v_raw      RAW(57);
    v_length   INTEGER := 0;
    v_offset   INTEGER := 1;

    -- Seta as variávels para conexão do servidor
    v_smtp_server VARCHAR2(100) := 'IP_DO_SERVIDOR';
    v_smtp_domain VARCHAR2(80) := 'SERVER_NAME';

    -- Variavel para tratar mais de um destinatario
    v_listadestinatarios VARCHAR2(2000) := ppara;
    v_destinatario       VARCHAR2(80) := '';

    /*Adiciona informações do cabeçalho*/
    PROCEDURE send_header(NAME IN VARCHAR2, header IN VARCHAR2) AS
    BEGIN
        utl_smtp.write_data(vconexao, NAME || ': ' || header || utl_tcp.crlf);
    END;

--- Converte ASC2 para HTML 
FUNCTION asc2html(str1 IN VARCHAR2) RETURN VARCHAR2 is
    pos     INT;
    chars_s VARCHAR2(255)  := '¡,¢,£,¤,¥,¦,§,¨,©,ª,«,¬,®,¯,°,±,²,³,´,µ,¶,·,¸,¹,º,»,¼,½,¾,¿,À,Á,Â,Ã,Ä,Å,Æ,Ç,È,É,Ê,Ë,Ì,Í,Î,Ï,Ð,não,Ò,Ó,Ô,Õ,Ö,×,Ø,Ù,Ú,Û,Ü,Ý,Þ,ß,à,á,â,ã,ä,å,æ,ç,è,é,ê,ë,ì,í,î,ï,ð,não,ò,ó,ô,õ,ö,÷,ø,ù,ú,û,ü,ý,þ,ÿ,¿,¿,¿,¿,¿,¿,¿,`,¿,¿,¿,¿,¿,¿,¿,¿,¿,¿,¿,¿';
    chars_r VARCHAR2(2000) := '&#161;,&#162;,&#163;,&#164;,&#165;,&#166;,&#167;,&#168;,&#169;,&#170;,&#171;,&#172;,&#174;,&#175;,&#176;,&#177;,&#178;,&#179;,&#180;,&#181;,&#182;,&#183;,&#184;,&#185;,&#186;,&#187;,&#188;,&#189;,&#190;,&#191;,&#192;,&#193;,&#194;,&#195;,&#196;,&#197;,&#198;,&#199;,&#200;,&#201;,&#202;,&#203;,&#204;,&#205;,&#206;,&#207;,&#208;,&#209;,&#210;,&#211;,&#212;,&#213;,&#214;,&#215;,&#216;,&#217;,&#218;,&#219;,&#220;,&#221;,&#222;,&#223;,&#224;,&#225;,&#226;,&#227;,&#228;,&#229;,&#230;,&#231;,&#232;,&#233;,&#234;,&#235;,&#236;,&#237;,&#238;,&#239;,&#240;,&#241;,&#242;,&#243;,&#244;,&#245;,&#246;,&#247;,&#248;,&#249;,&#250;,&#251;,&#252;,&#253;,&#254;,&#255;,&#338;,&#339;,&#352;,&#353;,&#402;,&#8211;,&#8212;,&#8216;,&#8217;,&#8218;,&#8220;,&#8221;,&#8222;,&#8224;,&#8225;,&#8226;,&#8230;,&#8240;,&#8364;,&#8482;';
    str     VARCHAR2(3000);
    strproc VARCHAR2(3000);
    strsub  VARCHAR2(3000);
BEGIN
    str := str1;
    pos := 1;
    WHILE instr(chars_s, ',', 1, pos) > 0 LOOP
        SELECT substr(chars_s,
                      decode(pos, 1, 1, instr(chars_s, ',', 1, pos - 1) + 1),
                      decode(pos,
                             1,
                             instr(chars_s, ',', 1, pos) - 1,
                             instr(chars_s, ',', 1, pos) - instr(chars_s, ',', 1, pos - 1) - 1)),
               substr(chars_r,
                      decode(pos, 1, 1, instr(chars_r, ',', 1, pos - 1) + 1),
                      decode(pos,
                             1,
                             instr(chars_r, ',', 1, pos) - 1,
                             instr(chars_r, ',', 1, pos) - instr(chars_r, ',', 1, pos - 1) - 1))                             
          INTO strproc, strsub
          FROM dual;
        -- dbms_output.put_line(' Pos.: ' || pos || ' Proc :' || strproc || ' Sub:' || strsub);
        pos := pos + 1;
        str := REPLACE(str, strproc, strsub);
    END LOOP;
    RETURN str;
END;
BEGIN
    /*Setando conexão com o servidor*/
    vconexao := utl_smtp.open_connection(v_smtp_server, 25);
    utl_smtp.helo(vconexao, v_smtp_domain);

    /*Envio de e-mail com autenticação.*/
    utl_smtp.command(vconexao, 'AUTH LOGIN');
    utl_smtp.command(vconexao,
                     utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw((pusuario)))));
    utl_smtp.command(vconexao,
                     utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw((psenha)))));

    /*Informando Remetente e Destinatário*/
    utl_smtp.mail(vconexao, pde);
    v_listadestinatarios := ppara;
    
    LOOP
        IF instr(v_listadestinatarios, ',') > 0 THEN
            v_destinatario       := substr(v_listadestinatarios,
                                           1,
                                           instr(v_listadestinatarios, ',') - 1);
            v_listadestinatarios := substr(v_listadestinatarios,
                                           instr(v_listadestinatarios, ',') + 1,
                                           length(v_listadestinatarios));
        ELSE
            v_destinatario       := v_listadestinatarios;
            v_listadestinatarios := '';
        END IF;
        IF rtrim(v_destinatario) IS NOT NULL THEN
            utl_smtp.rcpt(vconexao, v_destinatario);
        END IF;
        EXIT WHEN rtrim(v_listadestinatarios) IS NULL;
    END LOOP;
    --utl_smtp.rcpt(vConexao, pPara);

    /*Informando Dados do Cabeçalho*/
    utl_smtp.open_data(vconexao);
    send_header('From', '"' || pde || '" <' || pde || '>');

    v_listadestinatarios := ppara;
    LOOP
        IF instr(v_listadestinatarios, ',') > 0 THEN
            v_destinatario       := substr(v_listadestinatarios,
                                           1,
                                           instr(v_listadestinatarios, ',') - 1);
            v_listadestinatarios := substr(v_listadestinatarios,
                                           instr(v_listadestinatarios, ',') + 1,
                                           length(v_listadestinatarios));
        ELSE
            v_destinatario       := v_listadestinatarios;
            v_listadestinatarios := '';
        END IF;
        IF v_destinatario IS NOT NULL THEN
            send_header('To', '"' || v_destinatario || '" <' || v_destinatario || '>');
        END IF;
        EXIT WHEN rtrim(v_listadestinatarios) IS NULL;
    END LOOP;

    send_header('Subject', passunto);

    /*É necessário informar os caracteres <CR><LF> como terminador das linhas*/
    /*Utilizar a linha abaixo quando for enviado um texto html*/
    utl_smtp.write_data(vconexao, 'MIME-Version: 1.0' || utl_tcp.crlf);
    utl_smtp.write_data(vconexao,
                        'Content-Type: multipart/alternative; boundary="' || l_boundary || '"' ||
                        utl_tcp.crlf || utl_tcp.crlf);
    utl_smtp.write_data(vconexao, '--' || l_boundary || utl_tcp.crlf);

    utl_smtp.write_data(vconexao,
                        'Content-Type: text/html; charset="UTF-8"' || utl_tcp.crlf || utl_tcp.crlf);

    /*Anexar o corpo da mensagem*/
    utl_smtp.write_data(vconexao, [b]asc2html(BODY )[/b]);
    utl_smtp.write_data(vconexao, utl_tcp.crlf || utl_tcp.crlf);
--    utl_smtp.write_data(vconexao, '--' || l_boundary || '--' || utl_tcp.crlf);

   [b][i] /*Anexar arquivo na mensagem */[/i][/b]
    IF p_attach_name IS NOT NULL
       AND p_attach_blob IS NOT NULL THEN
        utl_smtp.write_data(vconexao, '--' || l_boundary || utl_tcp.crlf);
        utl_smtp.write_data(vconexao, 'Content-Type: ' || p_attach_mime || '; name="' || p_attach_name || '"' ||utl_tcp.crlf);
        utl_smtp.write_data(vconexao, 'Content-Transfer-Encoding: base64' || utl_tcp.crlf);
        utl_smtp.write_data(vconexao, 'Content-Disposition: attachment; filename="' || p_attach_name || '"' || utl_tcp.crlf || utl_tcp.crlf);
    
        v_length := dbms_lob.getlength(p_attach_blob);
    
        <<while_loop>>
        WHILE v_offset < v_length LOOP
            dbms_lob.read(p_attach_blob, l_step, v_offset, v_raw);
            utl_smtp.write_raw_data(vconexao, utl_encode.base64_encode(v_raw));
            utl_smtp.write_data(vconexao, utl_tcp.crlf);
            v_offset := v_offset + l_step;
        END LOOP while_loop;
    END IF;

    utl_smtp.write_data(vconexao, utl_tcp.crlf || utl_tcp.crlf);
    utl_smtp.write_data(vconexao, '--' || l_boundary || '--' || utl_tcp.crlf);

    /*Fechar a entrada de dados*/
    utl_smtp.close_data(vconexao);

    /*Enviar o email*/
    utl_smtp.quit(vconexao);
EXCEPTION
    WHEN utl_smtp.transient_error
         OR utl_smtp.permanent_error THEN
        utl_smtp.quit(vconexao);
        raise_application_error(-20000, 'Erro ao tentar enviar e-mail: ' || SQLERRM);
END;
