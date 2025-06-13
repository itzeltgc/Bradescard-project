# Segmentación y predicción de pagos para clientes Bradescard

El proyecto busca comprender el comportamiento de los clientes a través de variables clave que reflejan patrones de uso, riesgo, y morosidad. Utilizando redes bayesianas, se identificaron relaciones de dependencia entre factores con los que se estima la **probabilidad de pago** dadas cierta evidencia histórica. Con lo cual, buscamos brindar la mayor libertad al usuario para la toma de decisiones y orientación en acciones estratégicas para la prevención de morosidad, recuperación o reactivación de cuentas. 


## 📑 Implementación
El proyecto sigue la siguiente estructura
1. **Limpieza y separación de bases de datos** en cinco tipos de clientes que presentan características particulares 
2. **Feature Engineering** para el diseño de indicadores categóricos a usar en el modelo
3. **Creación del Modelo**, una Red Bayesiana Multinomial 
4. **Visulización y simulación** de predicciones de pago dadas ciertas características de los clientes


## 💻 Tecnologías empleadas
| Herramienta     |  Uso principal  |
|--------------|---------------|
| Python | Lenguaje principal del backend | 
| R/Rstudio | Implementación de la red bayesiana |
| Shiny | Creación de la Interfaz |
| Pandas & numpy | Manipulación y limpieza de datos |



## 👥 Miembros del equipo
* Brenda Itzelt Gómez Catzín
* Gabriela Lujan
* Gabriel Reynoso 
* Valeria Aguilar Meza
* Ariel López
