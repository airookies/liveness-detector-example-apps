import { defineConfig } from 'vitepress'

export default defineConfig({
  lang: 'mn-MN',
  title: 'LivenessDetector',
  description: 'LivenessDetector 5 мобайл SDK-ийн амьд байдлын шалгалтыг апп-даа холбох заавар',
  base: '/liveness-detector-example-apps/',
  markdown: {
    container: {
      tipLabel: 'Зөвлөгөө',
      warningLabel: 'Анхаар',
      dangerLabel: 'Аюул',
      infoLabel: 'Мэдээлэл',
      detailsLabel: 'Дэлгэрэнгүй',
    },
  },
  themeConfig: {
    nav: [
      { text: 'Эхлэх', link: '/guide/access' },
      {
        text: 'Платформ',
        items: [
          { text: 'Android', link: '/guide/android' },
          { text: 'iOS', link: '/guide/ios' },
          { text: 'React Native', link: '/guide/react-native' },
          { text: 'Flutter', link: '/guide/flutter' },
        ],
      },
      { text: 'Жишээ апп', link: 'https://github.com/airookies/liveness-detector-example-apps' },
    ],
    sidebar: [
      {
        text: 'Эхлэх',
        items: [
          { text: 'Хандалт ба токен', link: '/guide/access' },
          { text: 'Backend урсгал', link: '/guide/backend' },
        ],
      },
      {
        text: 'Платформ',
        items: [
          { text: 'Android', link: '/guide/android' },
          { text: 'iOS', link: '/guide/ios' },
          { text: 'React Native', link: '/guide/react-native' },
          { text: 'Flutter', link: '/guide/flutter' },
        ],
      },
      {
        text: 'Лавлах',
        items: [
          { text: 'Үр дүн ба шалтгаан', link: '/guide/result' },
          { text: 'Тохиргоо ба загвар', link: '/guide/options' },
          { text: 'Алдаа засах', link: '/guide/troubleshooting' },
        ],
      },
    ],
    outline: { label: 'Энэ хуудсанд', level: [2, 3] },
    docFooter: { prev: 'Өмнөх', next: 'Дараах' },
    darkModeSwitchLabel: 'Харагдац',
    lightModeSwitchTitle: 'Цайвар горим',
    darkModeSwitchTitle: 'Бараан горим',
    sidebarMenuLabel: 'Цэс',
    returnToTopLabel: 'Дээш буцах',
    skipToContentLabel: 'Агуулга руу очих',
    notFound: { title: 'Хуудас олдсонгүй', quote: '', linkText: 'Нүүр хуудас' },
    search: {
      provider: 'local',
      options: {
        translations: {
          button: { buttonText: 'Хайх', buttonAriaLabel: 'Хайх' },
          modal: {
            noResultsText: 'Илэрц олдсонгүй',
            resetButtonTitle: 'Цэвэрлэх',
            backButtonTitle: 'Хаах',
            displayDetails: 'Дэлгэрэнгүй',
            footer: { selectText: 'сонгох', navigateText: 'шилжих', closeText: 'хаах' },
          },
        },
      },
    },
  },
})
