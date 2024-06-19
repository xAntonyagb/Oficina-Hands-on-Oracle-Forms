CREATE TABLE TIPO_VEICULO(
       nr_codigo  NUMBER,
       ds_tipo    VARCHAR(20),
       qtd_portas NUMBER(10),
       qtd_rodas  NUMBER(10),
       dt_record  DATE,
CONSTRAINT pk_codigo PRIMARY KEY(nr_codigo)
);



CREATE TABLE Carro(
       nr_placa VARCHAR2(7),
       ds_marca VARCHAR2(30),
       ds_cor   VARCHAR2(30),
       dt_ano   NUMBER(4),
       vl_km    VARCHAR2(20),
       cd_tipo  NUMBER,
CONSTRAINT pk_placa PRIMARY KEY(nr_placa),
CONSTRAINT fk_carro_tipo FOREIGN KEY(cd_tipo) REFERENCES TIPO_VEICULO(nr_codigo)
);
