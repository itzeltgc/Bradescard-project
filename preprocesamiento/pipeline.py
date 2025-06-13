def limpieza(ruta_archivo):
    """
    Función  que toma una ruta para un archivo txt con datos de clientes y realiza una serie de transformaciones y limpiezas en los datos.
    - Agrupa los clientes por su límite de crédito en categorías.
    - Renombra las variables de meses para mayor claridad.
    - Filtra clientes de préstamo personal.
    - Identifica clientes nuevos y fieles, y clasifica a los clientes según su comportamiento de pago.
    - Calcula la inactividad de los clientes y categoriza su comportamiento.
    - Calcula el comportamiento de pago y la deuda de los clientes.
    - Devuelve un DataFrame con las variables de interés y las transformaciones realizadas.
    
    Input:
    ruta_archivo: str
        Ruta al archivo CSV que contiene los datos de los clientes.
    Output:
    pandas.DataFrame
        DataFrame con las variables de interés y las transformaciones realizadas.
        
    Ejemplo de uso en otro script:
    from Pipeline_limpieza import limpieza
    df_limpio = limpieza("ruta/al/archivo.csv")
    """
    
    
    import pandas as pd 
    import numpy as np

    data = pd.read_csv(ruta_archivo, delimiter=",", low_memory=False, encoding="latin")

    #grupo credito
    bins = [0, 1000, 5000, 15000, data["Limite_credito"].max()]
    labels = ["Bajo", "Medio-Bajo", "Medio-Alto", "Alto"]
    data["Grupo_Credito"] = pd.cut(data["Limite_credito"], bins=bins, labels=labels)

    # renombramos las variables de meses con M0 para mayor facilidad 
    data.rename(columns = {"Saldo_total": "Saldo_total_M0", "Saldo_Mes": "Saldo_Mes_M0", "Pago_minimo": "Pago_minimo_M0", "Pago": "Pago_M0", "Utilizacion": "Utilizacion_M0", "Fecha_corte": "Fecha_corte_M0", "Fecha_limite_pago": "Fecha_limite_pago_M0", "Fecha_pago": "Fecha_pago_M0", "Fecha_prox_corte": "Fecha_prox_corte_M0", "Behavior": "Behavior_M0", "Ciclo_Atraso": "Ciclo_atraso_M0"}, inplace = True)

    #clientes prestamo personal 
    clientes_prestamo_personal = data[data["Producto"] == "PP"]
    data.drop(clientes_prestamo_personal.index, inplace = True)

    #clientes nuevos y sobregiro
    data["Fecha_corte_M0"] = pd.to_datetime(data["Fecha_corte_M0"], format="%d/%m/%Y")
    data["Fecha_activacion"] = pd.to_datetime(data["Fecha_activacion"], format="%d/%m/%Y")
    fecha_referencia = data["Fecha_corte_M0"].max()
    data["cliente_nuevo"] = (data["Fecha_activacion"] >= fecha_referencia - pd.DateOffset(months = 6))
    data["cliente_fiel"] = ~data["cliente_nuevo"]
    data["tipo_cliente"] = np.where(data["cliente_nuevo"], "cliente_nuevo", "cliente_fiel")
    data.drop(columns = ["cliente_nuevo", "cliente_fiel"], inplace = True)
    clientes_fieles = data[data["tipo_cliente"] == "cliente_fiel"]
    clientes_nuevos = data[data["tipo_cliente"] == "cliente_nuevo"]
    utilizacion_cuestionable = clientes_fieles[(clientes_fieles["Grupo_Credito"] == "Bajo") | (clientes_fieles["Grupo_Credito"] == "Medio-Bajo")]
    clientes_sobregiro = utilizacion_cuestionable[(utilizacion_cuestionable["Utilizacion_M0"] > 1) & (utilizacion_cuestionable["Limite_credito"] == 1)]
    data = clientes_fieles.drop(clientes_sobregiro.index)


    #variables de interes
    variables_de_interes = ['ORG', 'Fecha_activacion', 'Saldo_total_M0', 'Saldo_Mes_M0', 'Pago_minimo_M0',
        'Utilizacion_M0', 'Corte', 'Fecha_corte_M0', 'Fecha_limite_pago_M0',
        'Fecha_prox_corte_M0', 'Pago_M0', 'Fecha_pago_M0', 'Limite_credito', 'Behavior_M0', 'Ciclo_atraso_M0', 'Saldo_total_M1', 'Saldo_total_M2', 'Saldo_total_M3',
        'Saldo_total_M4', 'Saldo_total_M5', 'Saldo_total_M6', 'Saldo_Mes_M1',
        'Saldo_Mes_M2', 'Saldo_Mes_M3', 'Saldo_Mes_M4', 'Saldo_Mes_M5',
        'Saldo_Mes_M6', 'Pago_minimo_M1', 'Pago_minimo_M2', 'Pago_minimo_M3',
        'Pago_minimo_M4', 'Pago_minimo_M5', 'Pago_minimo_M6', 'Fecha_corte_M1',
        'Fecha_corte_M2', 'Fecha_corte_M3', 'Fecha_corte_M4', 'Fecha_corte_M5',
        'Fecha_corte_M6', 'Fecha_limite_pago_M1', 'Fecha_limite_pago_M2',
        'Fecha_limite_pago_M3', 'Fecha_limite_pago_M4', 'Fecha_limite_pago_M5',
        'Fecha_limite_pago_M6', 'Fecha_prox_corte_M1', 'Fecha_prox_corte_M2',
        'Fecha_prox_corte_M3', 'Fecha_prox_corte_M4', 'Fecha_prox_corte_M5',
        'Fecha_prox_corte_M6', 'Utilizacion_M1', 'Utilizacion_M2', 'Utilizacion_M3',
        'Utilizacion_M4', 'Utilizacion_M5', 'Utilizacion_M6', 'Behavior_M1',
        'Behavior_M2', 'Behavior_M3', 'Behavior_M4', 'Behavior_M5',
        'Behavior_M6', 'Ciclo_atraso_M1', 'Ciclo_atraso_M2','Ciclo_atraso_M3',
        'Ciclo_atraso_M4','Ciclo_atraso_M5','Ciclo_atraso_M6', 'Pago_M1', 'Pago_M2', 'Pago_M3', 'Pago_M4', 'Pago_M5',
        'Pago_M6', 'Fecha_pago_M1', 'Fecha_pago_M2', 'Fecha_pago_M3',
        'Fecha_pago_M4', 'Fecha_pago_M5', 'Score_pago', 'Variable_objetivo', 'Grupo_Credito',
        'tipo_cliente']

    data = data[variables_de_interes]
    #datetime
    for col in data.columns:
        if 'Fecha' in col:
            data[col] = pd.to_datetime(data[col], format="%d/%m/%Y", errors='coerce')

    #fill with 0
    for col in data.columns:
        if data[col].dtype == 'float' or data[col].dtype == 'int':
            data[col] = data[col].fillna(0)
            
    meses = ['M6', 'M5', 'M4', 'M3', 'M2', 'M1', 'M0']
    for mes in meses:
        data[f"Inactivo_{mes}"] = (
            (data[f"Saldo_total_{mes}"] == 0) &
            (data[f"Saldo_Mes_{mes}"] == 0) &
            (data[f"Pago_{mes}"] == 0) &
            (data[f"Pago_minimo_{mes}"] == 0) &
            (data[f"Utilizacion_{mes}"] == 0) 
        )
        

        

    # contamos cuántos meses seguidos cada cliente ha estado inactivo
    data["Meses_Inactivo"] = data[[f"Inactivo_{mes}" for mes in meses]].sum(axis=1)

    # Reordenamos las columnas de inactividad en orden cronológico
    cols_inactividad = [f"Inactivo_{mes}" for mes in meses] 

    # Función que calcula la racha de inactividad más larga de inactividad
    def contar_inactidad(row):
        max_racha, racha_actual = 0, 0
        for mes in cols_inactividad:
            if row[mes]:
                racha_actual += 1
                max_racha = max(max_racha, racha_actual)
            else:
                racha_actual = 0
        return max_racha

    # Aplicamos la función fila por fila
    data["max_meses_inactivos_consecutivos"] = data.apply(contar_inactidad, axis=1)

    data["deuda_antes_inactividad"] = False

    for idx, row in data.iterrows():
        if row["max_meses_inactivos_consecutivos"] >= 1:
            for i in range(len(meses)):
                mes = meses[i]
                if row[f"Inactivo_{mes}"]:
                    if i + 1 >= len(meses):
                        break
                    mes_anterior = meses[i + 1]
                    if row.get(f"Saldo_total_{mes_anterior}", 0) > 0:
                        data.at[idx, "deuda_antes_inactividad"] = True
                    break
                

    condiciones = [
        (data["max_meses_inactivos_consecutivos"].isin([4, 5, 6])) & (~data["deuda_antes_inactividad"]),
        (data["max_meses_inactivos_consecutivos"].isin([1, 2, 3, 4, 5, 6])) & (data["deuda_antes_inactividad"]),
        (data["max_meses_inactivos_consecutivos"] == 0)
    ]

    # resultados para cada condición
    comportamientos = [
        "cliente_inactivo_sin_deuda",
        "cliente_inactivo_con_deuda",
        "cliente_activo"
    ]

    # todo lo que no entra en esas categorías será "cliente_irregular"
    data["comportamiento_cliente"] = np.select(condiciones, comportamientos, default="cliente_irregular")

    data = data[data["comportamiento_cliente"] != "cliente_irregular"]

    data.reset_index(drop=True, inplace=True)

    cols_morosidad = [f"Ciclo_atraso_M{i}" for i in range(6, -1, -1)]  # M6 -> M0
    cols_pago_total = [f"Pago_M{i}" for i in range(6, -1, -1)]
    for i in range(6, -1, -1):
        data[f"pago_total_M{i}"] = ((data[f"Saldo_total_M{i}"] > 0) & (data[f"Pago_M{i}"] >= data[f"Saldo_total_M{i}"])).astype(int)
        data[f"pago_parcial_M{i}"] = ((data[f"Pago_M{i}"] > 0) & (data[f"Pago_M{i}"] < data[f"Saldo_total_M{i}"])).astype(int)
        data[f"pago_nulo_M{i}"] = ((data[f"Pago_M{i}"] == 0) & (data[f"Saldo_total_M{i}"] > 0)).astype(int)
    data["pago_total_deuda"] = data[[f"pago_total_M{i}" for i in range(6, -1, -1)]].sum(axis=1)
    data["pago_parcial_deuda"] = data[[f"pago_parcial_M{i}" for i in range(6, -1, -1)]].sum(axis=1)
    data["pago_nulo_deuda"] = data[[f"pago_nulo_M{i}" for i in range(6, -1, -1)]].sum(axis=1)
    def categorizar_pago(meses):
        if meses >= 6:
            return "Alta"
        elif 3 <= meses < 6:
            return "Media"
        elif 1 <= meses < 3:
            return "Baja"
        else:
            return "Nula"
    data["comportamiento_pago_total"] = data["pago_total_deuda"].apply(categorizar_pago)
    data["comportamiento_pago_parcial"] = data["pago_parcial_deuda"].apply(categorizar_pago)
    data["comportamiento_pago_nulo"] = data["pago_nulo_deuda"].apply(categorizar_pago)
    for i in range(6, -1, -1):
        data[f"deuda_M{i}"] = (
            np.where(data[f"Saldo_total_M{i}"] > 0, 
                    (data[f"Saldo_total_M{i}"] - data[f"Pago_M{i}"]).clip(lower=0),
                    np.nan)
        )
    mapeo_atraso = {
        0: "sin_actividad",
        1: "al_dia",              # 0 días
        2: "atraso_aceptable",    # 1-30 días
        3: "medio_atraso",        # 31-60 días
        4: "alto_atraso_1",         # 61-90 días
        5: "alto_atraso_2",         # 91-120 días
        6: "critico_atraso_1",      # 121-150 días
        7: "critico_atraso_2",      # 151-180 días
        8: "extremo_atraso_1",      # 181-210 días
        9: "extremo_atraso_2"       # >211 días
    }
    data[cols_morosidad] = data[cols_morosidad].replace(mapeo_atraso)
    # Orden para comparar las categorías de atraso
    orden_atraso = ["sin_actividad","al_dia", "atraso_aceptable", "medio_atraso", "alto_atraso_1", "alto_atraso_2", 
                    "critico_atraso_1", "critico_atraso_2", "extremo_atraso_1" , "extremo_atraso_2"]
    cols_deuda_mensual = [f"deuda_M{i}" for i in range(6, -1, -1)]
    data["deuda_promedio_semestral"] = data[cols_deuda_mensual].mean(axis=1)
    cuartiles = data["deuda_promedio_semestral"].quantile([0.25, 0.5, 0.75])

    q1, q2, q3 = cuartiles[0.25], cuartiles[0.5], cuartiles[0.75]

    def categorizar_deuda(x):
        if x <= q1:
            return "Baja"
        elif q1 < x <= q2:
            return "Media-baja"
        elif q2 < x <= q3:
            return "Media-alta"
        else:
            return "Alta"

    data["categoria_deuda"] = data["deuda_promedio_semestral"].apply(categorizar_deuda)
    data["max_morosidad"] = data[cols_morosidad].apply(lambda row: max(row, key=lambda x: orden_atraso.index(x)), axis=1)

    data.reset_index(drop=True, inplace=True)
    # Guardamos el DataFrame final en un archivo CSV
    return data


