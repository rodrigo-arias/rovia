--------------------------------------------------------------------------------------------------------
-- CONSULTAS
--------------------------------------------------------------------------------------------------------
USE BD_VEHICULOS;
GO
-- QUERY A
SELECT MAX(pesoEnvio) AS  'Máximo Peso del Período', MIN(pesoEnvio) AS 'Mínimo Peso del Período', MAX(fchEnvio) AS 'Mayor Fecha del Período', MIN(fchEnvio) AS 'Menor Fecha del Período'
FROM Envios
WHERE YEAR(fchEnvio) IN (2015,2016)
GO
--------------------------------------------------------------------------------------------------------
-- QUERY B
SELECT F.nomFab AS 'Nombre del Fabricante', COUNT(nomFab) AS 'Vehiculos Enviados', SUM(V.peso) AS 'Peso Total en 2016'
FROM Fabricantes F, Vehiculos V, Carga C, Envios E
WHERE F.codFab = V.codFab AND V.vin = C.vin AND E.idEnvio = C.idEnvio AND YEAR(E.fchEnvio) = 2016
GROUP BY F.nomFab
ORDER BY SUM(V.peso) DESC
GO
--------------------------------------------------------------------------------------------------------
-- QUERY C
SET DATEFORMAT DMY
SELECT nomPais 'Nombre de País', (SELECT COUNT(desEnvio)
                                  FROM Envios
                                  WHERE Paises.codPais = Envios.desEnvio AND Envios.fchEnvio BETWEEN '01/01/2016' AND '20/01/2016'
                                  GROUP BY desEnvio) AS 'Cant. de Envíos',
                                 (SELECT MAX(Envios.fchEnvio)
                                  FROM Envios
                                  WHERE Paises.codPais = Envios.desEnvio AND Envios.fchEnvio BETWEEN '01/01/2016' AND '20/01/2016') AS 'Última Fecha Envío'
FROM Paises
GO
--------------------------------------------------------------------------------------------------------
-- QUERY D
SELECT *
FROM Fabricantes
WHERE codFab IN (SELECT F.codFab
                 FROM Fabricantes F, Vehiculos V, Carga C, Envios E
                 WHERE F.codFab = V.codFab AND V.vin = C.vin AND E.idEnvio = C.idEnvio
                 GROUP BY F.codFab, E.idEnvio
                 HAVING COUNT(C.vin) > 0) AND
	codFab NOT IN ((SELECT fabEnvios.codFab
					        FROM (SELECT COUNT(auxTable.codFab) as 'cantEnvios', auxTable.codFab
							          FROM (SELECT F.codFab
								              FROM Fabricantes F, Vehiculos V, Carga C, Envios E
								              WHERE F.codFab = V.codFab AND V.vin = C.vin AND E.idEnvio = C.idEnvio
								              GROUP BY F.codFab, E.idEnvio
								              HAVING COUNT(C.vin) < 2) auxTable
							          GROUP BY auxTable.codFab) fabEnvios
						      WHERE fabEnvios.cantEnvios > 3))
GO
--------------------------------------------------------------------------------------------------------
-- QUERY E
SELECT V.*
FROM Vehiculos V, Carga C, Envios E
WHERE V.vin = C.vin AND C.idEnvio  = E.idEnvio AND E.fchEnvio = (SELECT MAX(fchEnvio)
                                                                 FROM Envios)
GO
--------------------------------------------------------------------------------------------------------
-- QUERY F
SET DATEFORMAT DMY
SELECT F.*
FROM Fabricantes F
WHERE F.codFab NOT IN (SELECT F.codFab
				               FROM Vehiculos V, Carga C, Envios E
				               WHERE F.codFab = V.codFab AND V.vin = C.vin AND E.idEnvio = C.idEnvio AND E.fchEnvio BETWEEN '01/01/2016' AND '30/06/2016')
AND F.codFab IN (SELECT F.codFab
                FROM Vehiculos V, Carga C, Envios E
                WHERE F.codFab = V.codFab AND V.vin = C.vin AND E.idEnvio = C.idEnvio AND YEAR(E.fchEnvio) = '2017')
AND F.codFab IN (SELECT F.codFab
               FROM Vehiculos V, Carga C, Envios E, Paises P
               WHERE F.codFab = V.codFab AND V.vin = C.vin AND E.idEnvio = C.idEnvio AND P.codPais = E.desEnvio AND P.nomPais = 'Holanda')
GO
--------------------------------------------------------------------------------------------------------
 -- QUERY G
 SELECT V.vin, V.modelo, V.color, V.peso, V.caracteristicas, V.codPais, V.codFab, MAX(E.fchEnvio) AS 'fechaUlt.Envío', F.nomFab
 FROM Fabricantes F, Vehiculos V, Carga C, Envios E
 WHERE F.codFab = V.codFab AND V.vin = C.vin AND E.idEnvio = C.idEnvio AND
 V.vin IN (SELECT V.vin
           WHERE V.peso < 2300)
 GROUP BY V.vin, V.modelo, V.color, V.peso, V.caracteristicas, V.codPais, V.codFab, F.nomFab
 GO
--------------------------------------------------------------------------------------------------------
-- QUERY H
UPDATE Vehiculos
SET peso = peso - peso * 0.05
WHERE vin NOT IN (SELECT V.vin
                  FROM Vehiculos V, Carga C, Envios E
                  WHERE V.vin = C.vin AND C.idEnvio = E.idEnvio AND YEAR(fchEnvio) >= dbo.fnAnioVehiculo(V.vin) + 1)
GO
--------------------------------------------------------------------------------------------------------
-- QUERY I
SELECT DISTINCT Fabricantes.*
FROM Fabricantes, Plantas, Paises
WHERE Fabricantes.codFab = Plantas.codFab AND Plantas.codPais = Paises.codPais AND Paises.nomPais = 'Japón' AND
Fabricantes.codFab IN (SELECT F.codFab
					   FROM Fabricantes F, Vehiculos V, Carga C, Envios E
					   WHERE F.codFab = V.codFab AND V.vin = C.vin AND E.idEnvio = C.idEnvio AND YEAR(E.fchEnvio) = 2016
					   GROUP BY F.codFab, MONTH(E.fchEnvio)
					   HAVING COUNT(C.vin) > 100) AND
Fabricantes.codFab IN (SELECT F.codFab
					   FROM Fabricantes F, Vehiculos V, Carga C, Envios E
					   WHERE F.codFab = V.codFab AND V.vin = C.vin AND E.idEnvio = C.idEnvio AND YEAR(E.fchEnvio) = 2016
					   GROUP BY F.codFab, MONTH(E.fchEnvio)
					   HAVING COUNT(C.vin) < 20)
GO
--------------------------------------------------------------------------------------------------------
-- VISTAS
--------------------------------------------------------------------------------------------------------
USE BD_VEHICULOS;
GO
-- CREATE VIEW
CREATE VIEW VehiculosFabricacionExportacion
AS
  (SELECT auxTable.vin, auxTable.paisFabricacion, COUNT(auxTable.vin) AS 'vehiculosExportados'
   FROM (SELECT V.vin, P.nomPais as 'paisFabricacion', E.desEnvio AS 'destEnvio'
	       FROM Envios E, Carga C, Vehiculos V, Paises P
	       WHERE E.idEnvio = C.idEnvio AND C.vin = V.vin AND V.codPais = P.codPais AND E.desEnvio <> V.codPais) auxTable
   GROUP BY auxTable.vin, auxTable.paisFabricacion)
GO
--------------------------------------------------------------------------------------------------------