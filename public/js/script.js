let articles=document.getElementsByTagName('article')
console.log(articles)

for(let i=0; i<articles.length; i++){
    articles[i].addEventListener('mouseover', (e)=>{
        let star1=document.querySelector(`article.lootbox_container:nth-child(${2+i})>div.rating > img`)
        let star2=document.querySelector(`article.lootbox_container:nth-child(${2+i})>div.rating > img:nth-child(2)`)
        let star3=document.querySelector(`article.lootbox_container:nth-child(${2+i})>div.rating > img:nth-child(3)`)
        
        star1.addEventListener('mouseover', (e)=>{
            star1.src='img/star-filled.png'

        })
        star1.addEventListener('mouseout', (e)=>{
            star1.src='img/star-empty.png'
        })

        star2.addEventListener('mouseover', (e)=>{
            star2.src='img/star-filled.png'
            star1.src='img/star-filled.png'

        })
        star2.addEventListener('mouseout', (e)=>{
            star2.src='img/star-empty.png'
            star1.src='img/star-empty.png'
        })

        star3.addEventListener('mouseover', (e)=>{
            star3.src='img/star-filled.png'
            star2.src='img/star-filled.png'
            star1.src='img/star-filled.png'

        })
        star3.addEventListener('mouseout', (e)=>{
            star3.src='img/star-empty.png'
            star2.src='img/star-empty.png'
            star1.src='img/star-empty.png'
        })
    })
}