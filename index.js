const fs = require("fs");

const reportOfServices = require("./reportOfServices"); // Сруктура отчета чеков по всем месяцам
const services = new Set(); // Все сервисы из исходного файла "чеки.txt"

const CHEKS_DIR = "./cheks"; // Путь до папки с исходными и результирующими данными

// Обработка исходого фала "чеки.txt"
fs.readFile(`${CHEKS_DIR}/чеки.txt`, "utf8", (err, data) => {
  if (err) {
    console.error(err);
    return;
  }
  // Получение данных в виде массива
  const resData = data.split("\r\n");
  resData.forEach((check) => {
    let service = check.split("_")[0];
    let month = check.split("_")[1].split(".")[0];
    // Добавление сервисов в коллекцию
    services.add(service);
    // Добавление оплаченного сервиса за определенный месяц
    reportOfServices[month].paid.push(service);
  });

  for (const reportingValue of Object.values(reportOfServices)) {
    // Добавление не оплаченных сервисов за определенный месяц
    services.forEach((service) => {
      if (!reportingValue.paid.includes(service))
        reportingValue.notPaid.push(service);
    });
  }

  // Формирование файла "чеки_по_папкам.txt"
  fs.writeFile(
    `${CHEKS_DIR}/чеки_по_папкам.txt`,
    convertDataToText(reportOfServices),
    (err) => {
      if (err) {
        console.error(err);
        return;
      }
      console.log("Данные успешно записаны в файл!");
    }
  );
});

// Метод преобразование данных из сформированной структуры в текст
function convertDataToText(data) {
  let resultText = "";
  // Разложение файлов по папкам месяцев в формате /месяц/название файла
  for (const [reportingMonth, reportingValue] of Object.entries(data)) {
    if (reportingValue.paid.length)
      reportingValue.paid.forEach((service) => {
        resultText += `/${reportingMonth}/${service}_${reportingMonth}.pdf\r\n`;
      });
  }

  resultText += "не оплачены:\r\n";

  // Указание, в каком месяце какая услуга не оплачена (если таковые имеются) в формат не оплачены:
  for (const [reportingMonth, reportingValue] of Object.entries(data)) {
    if (reportingValue.paid.length && reportingValue.notPaid.length) {
      resultText += `${reportingMonth}:\r\n`;
      reportingValue.notPaid.forEach((service) => {
        resultText += `${service}\r\n`;
      });
    }
  }
  return resultText;
}
